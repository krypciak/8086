const std = @import("std");

const memory = @import("memory.zig");
const RegisterMemory = memory.RegisterMemory;

const instruciton = @import("instruction.zig");
const Instruction = instruciton.Instruction;

const instruction_parser = @import("instruction_parser.zig");
const getValue = instruction_parser.getValue;

pub const Value = struct {
    const ShowValueType = enum {
        No,
        Byte,
        Word,
    };

    value: u16,

    pub fn toString(self: *const Value, allocator: std.mem.Allocator, show_value_type: ShowValueType) ![]const u8 {
        if (show_value_type == .No) {
            return std.fmt.allocPrint(allocator, "{d}", .{self.value});
        } else {
            return std.fmt.allocPrint(allocator, "{s} {d}", .{ if (show_value_type == .Word) "word" else "byte", self.value });
        }
    }
};

pub const RegisterAddress = struct {
    register: u8,
    wide: bool,

    pub fn toString(self: *const RegisterAddress, allocator: std.mem.Allocator) ![]const u8 {
        return std.fmt.allocPrint(allocator, "{s}", .{getRegName(self.register, self.wide)});
    }
};

pub const MemoryAddress = struct {
    displacement: i16 = 0,
    reg1: ?u8 = null,
    reg2: ?u8 = null,
    wide: bool,

    pub fn toString(self: *const MemoryAddress, allocator: std.mem.Allocator) ![]const u8 {
        if (self.reg1) |reg1| {
            const sign: u8 = if (self.displacement >= 0) '+' else '-';

            const r1 = getRegName(reg1, true);
            if (self.reg2) |reg2| {
                const r2 = getRegName(reg2, true);
                if (self.displacement == 0) {
                    return try std.fmt.allocPrint(allocator, "[{s} + {s}]", .{ r1, r2 });
                } else {
                    return try std.fmt.allocPrint(allocator, "[{s} + {s} {c} {d}]", .{ r1, r2, sign, @abs(self.displacement) });
                }
            } else {
                if (self.displacement == 0) {
                    return try std.fmt.allocPrint(allocator, "[{s}]", .{r1});
                } else {
                    return try std.fmt.allocPrint(allocator, "[{s} {c} {d}]", .{ r1, sign, @abs(self.displacement) });
                }
            }
        } else {
            return std.fmt.allocPrint(allocator, "[{d}]", .{self.displacement});
        }
    }
};

pub const AddressOrValue = union(AddressOrValue.Types) {
    pub const Types = enum {
        Value,
        RegisterAddress,
        MemoryAddress,
    };

    Value: Value,
    RegisterAddress: RegisterAddress,
    MemoryAddress: MemoryAddress,

    pub fn toString(self: *const AddressOrValue, allocator: std.mem.Allocator, show_value_type: Value.ShowValueType) ![]const u8 {
        return switch (self.*) {
            .Value => |*byte| byte.toString(allocator, show_value_type),
            .RegisterAddress => |*reg| reg.toString(allocator),
            .MemoryAddress => |*mem| mem.toString(allocator),
        };
    }
};

fn getRegName(val: u8, w: bool) []const u8 {
    const table_w0 = [8][]const u8{ "al", "cl", "dl", "bl", "ah", "ch", "dh", "bh" };
    const table_w1 = [8][]const u8{ "ax", "cx", "dx", "bx", "sp", "bp", "si", "di" };

    if (w) {
        return table_w1[val];
    } else {
        return table_w0[val];
    }
}

pub const MovLike = struct {
    pub const Type = enum {
        Mov,
        Add,
        Sub,
        Cmp,

        pub fn toString(self: *const Type) []const u8 {
            return switch (self.*) {
                .Mov => "mov",
                .Add => "add",
                .Sub => "sub",
                .Cmp => "cmp",
            };
        }
    };

    type: Type,
    to: AddressOrValue,
    from: AddressOrValue,

    pub fn toString(self: *const MovLike, allocator: std.mem.Allocator) ![]const u8 {
        const p1 = self.type.toString();

        const show_value_type: Value.ShowValueType = switch (self.to) {
            .MemoryAddress => |*mem| if (mem.wide) .Word else .Byte,
            else => .No,
        };

        const p2 = try self.to.toString(allocator, .No);
        const p3 = try self.from.toString(allocator, show_value_type);
        defer allocator.free(p2);
        defer allocator.free(p3);

        return std.fmt.allocPrint(allocator, "{s} {s}, {s}", .{ p1, p2, p3 });
    }

    pub fn execute(self: *const MovLike, registers: *RegisterMemory) !void {
        _ = self;
        _ = registers;
    }
};

pub fn movLike(data: []const u8, at: usize, mov_type: MovLike.Type, first_type: bool, check_sign: bool) !Instruction {
    const b1 = data[at];
    const b2 = data[at + 1];

    const w: bool = (b1 & 0b00000001) == 0b00000001;

    const mod: u8 = (b2 & 0b11000000) >> 6;

    const reg = (b2 & 0b00111000) >> 3;
    const rm = b2 & 0b00000111;

    var new_mov_type: MovLike.Type = mov_type;
    if (!first_type) {
        if (reg == 0b101) {
            std.debug.assert(mov_type == .Add);
            new_mov_type = .Sub;
        } else if (reg == 0b000) {
            std.debug.assert(mov_type == .Mov or mov_type == .Add);
        } else if (reg == 0b111) {
            std.debug.assert(mov_type == .Add);
            new_mov_type = .Cmp;
        }
    }

    if (mod == 0b11) { // register-to-register
        if (check_sign) {
            const s: bool = (b1 & 0b00000010) == 0b00000010;
            std.debug.assert(s);
            const value = getValue(data, at + 2, false);

            return Instruction{ .len = 3, .inst = .{ .MovLike = .{ .type = new_mov_type, .to = .{ .RegisterAddress = .{ .register = rm, .wide = w } }, .from = .{ .Value = .{ .value = @truncate(value) } } } } };
        } else {
            std.debug.assert(first_type);

            return Instruction{ .len = 2, .inst = .{ .MovLike = .{ .type = new_mov_type, .to = .{ .RegisterAddress = .{ .register = rm, .wide = w } }, .from = .{ .RegisterAddress = .{ .register = reg, .wide = w } } } } };
        }
    }

    const EMPTY = 100;
    const register_table = [8][2]u8{
        .{ 3, 6 },
        .{ 3, 7 },
        .{ 5, 6 },
        .{ 5, 7 },
        .{ 6, EMPTY },
        .{ 7, EMPTY },
        .{ 5, EMPTY },
        .{ 3, EMPTY },
    };
    const r1 = register_table[rm][0];
    const r2 = register_table[rm][1];

    var to: AddressOrValue = undefined;
    var from: AddressOrValue = undefined;

    var len: usize = undefined;

    if (first_type) to = .{ .RegisterAddress = .{ .register = reg, .wide = w } };
    if (mod == 0b00) {
        if (rm == 0b110) {
            len = 4;
            const value: u16 = getValue(data, at + 2, true);
            from = .{ .MemoryAddress = .{ .displacement = @bitCast(value), .wide = w } };
        } else {
            len = 2;
            if (r2 == EMPTY) {
                from = .{ .MemoryAddress = .{ .reg1 = r1, .wide = w } };
            } else {
                from = .{ .MemoryAddress = .{ .reg1 = r1, .reg2 = r2, .wide = w } };
            }
        }
    } else {
        const b3: u8 = data[at + 2];
        var displacement: i16 = undefined;
        if (mod == 0b01) {
            displacement = @as(i8, @bitCast(@as(u8, b3)));
            len = 3;
        } else {
            const b4: u16 = data[at + 3];
            displacement = @bitCast((b4 << 8) + b3);
            len = 4;
        }
        if (rm == 0b110) {
            std.debug.assert(displacement == 0);
            from = .{ .MemoryAddress = .{ .reg1 = r1, .wide = w } };
        } else {
            if (r2 == EMPTY) {
                from = .{ .MemoryAddress = .{ .reg1 = r1, .displacement = displacement, .wide = w } };
            } else {
                from = .{ .MemoryAddress = .{ .reg1 = r1, .reg2 = r2, .displacement = displacement, .wide = w } };
            }
        }
    }

    if (!first_type) {
        to = from;

        var value: u16 = undefined;
        if (rm == 0b11) {
            const b3: u16 = data[at + 2];
            value = b3;
            len = 3;
        } else {
            const s_flag: bool = (b1 & 0b00000010) == 0b00000010;
            const wide = w and (!check_sign or !s_flag);

            if (mod == 0b00 and rm != 0b110) {
                value = getValue(data, at + 2, wide);
                len = @max(len, 3 + @as(usize, @intFromBool(wide)));
            } else {
                value = getValue(data, at + 4, wide);
                len = @max(len, 5 + @as(usize, @intFromBool(wide)));
            }
        }
        from = .{ .Value = .{ .value = value } };
    } else if ((b1 & 0b00000010) != 0b00000010) { // check d
        const temp = from;
        from = to;
        to = temp;
    }

    return Instruction{ .len = len, .inst = .{ .MovLike = .{ .type = new_mov_type, .from = from, .to = to } } };
}

pub fn arithmeticImmediateFromAccumulator(data: []const u8, at: usize, movType: MovLike.Type) Instruction {
    const b1 = data[at];
    const w: bool = (b1 & 0b00000001) == 1;
    const value = getValue(data, at + 1, w);
    return Instruction{ .len = if (w) 3 else 2, .inst = .{ .MovLike = .{ .type = movType, .to = .{ .RegisterAddress = .{ .register = 0, .wide = w } }, .from = .{ .Value = .{ .value = value } } } } };
}

pub fn movImmediateToRegister(data: []const u8, at: usize) Instruction {
    const b1 = data[at];

    const w: bool = (b1 & 0b00001000) == 0b00001000;
    const reg = b1 & 0b00000111;

    const value: u16 = getValue(data, at + 1, w);
    return Instruction{ .len = if (w) 3 else 2, .inst = .{ .MovLike = .{ .type = .Mov, .to = .{ .RegisterAddress = .{ .register = reg, .wide = w } }, .from = .{ .Value = .{ .value = value } } } } };
}

pub fn movMemoryToAccumulator(data: []const u8, at: usize) Instruction {
    const b1 = data[at];

    const w: bool = (b1 & 0b00000001) == 1;

    const value: u16 = getValue(data, at + 1, w);

    var to: AddressOrValue = .{ .RegisterAddress = .{ .register = 0, .wide = w } };
    var from: AddressOrValue = .{ .MemoryAddress = .{ .displacement = @intCast(value), .wide = w } };

    if (b1 & 0b11111110 == 0b10100010) {
        const temp = from;
        from = to;
        to = temp;
    }

    return Instruction{ .len = 3, .inst = .{ .MovLike = .{ .type = .Mov, .to = to, .from = from } } };
}

const disassembler = @import("disassembler.zig");

test "mov register-to-register" {
    try disassembler.assertDisassembly("mov ax, bx");
    try disassembler.assertDisassembly("mov si, bx");
    try disassembler.assertDisassembly("mov dh, al");
}

test "mov 8-bit immediate-to-register" {
    try disassembler.assertDisassembly("mov cl, 12");
}

test "mov 16-bit immediate-to-register" {
    try disassembler.assertDisassembly("mov cx, 12");
    try disassembler.assertDisassembly("mov dx, 3948");
}

test "mov source address calculation" {
    try disassembler.assertDisassembly("mov dx, [si]");
    try disassembler.assertDisassembly("mov dx, [di]");
    try disassembler.assertDisassembly("mov dx, [bp]");
    try disassembler.assertDisassembly("mov dx, [bx]");
    try disassembler.assertDisassembly("mov bx, [bp + di]");
    try disassembler.assertDisassembly("mov al, [bx + si]");
}

test "mov source address calculation plus 8-bit displacement" {
    try disassembler.assertDisassembly("mov ah, [bx + si + 4]");
}

test "mov source address calculation plus 16-bit displacement" {
    try disassembler.assertDisassembly("mov al, [bx + si + 4999]");
}

test "mov dest address calculation" {
    try disassembler.assertDisassembly("mov [bx + di], cx");
    try disassembler.assertDisassembly("mov [bp + si], cl");
    try disassembler.assertDisassembly("mov [bp], ch");
    try disassembler.assertDisassembly("mov [si + 1], cx");
}

test "mov signed displacements" {
    try disassembler.assertDisassembly("mov ax, [bx + di - 37]");
    try disassembler.assertDisassembly("mov [si - 300], cx");
    try disassembler.assertDisassembly("mov dx, [bx - 32]");
}

test "mov explicit sizes" {
    try disassembler.assertDisassembly("mov [bp + di], byte 7");
    try disassembler.assertDisassembly("mov [di + 901], word 347");
    try disassembler.assertDisassembly("mov [bx], byte 34");
    try disassembler.assertDisassembly("mov [bp + si + 1000], word 29");
    try disassembler.assertDisassembly("mov [4834], byte 29");
    try disassembler.assertDisassembly("mov [4834], word 29");
}

test "mov direct address" {
    try disassembler.assertDisassembly("mov bp, [5]");
    try disassembler.assertDisassembly("mov bx, [3458]");
}

test "mov memory-to-accumulator test" {
    try disassembler.assertDisassembly("mov ax, [2555]");
    try disassembler.assertDisassembly("mov ax, [16]");
    try disassembler.assertDisassembly("mov al, [16]");
}

test "mov accumulator-to-memory test" {
    try disassembler.assertDisassembly("mov [2554], ax");
    try disassembler.assertDisassembly("mov [15], ax");
    try disassembler.assertDisassembly("mov [15], al");
}

test "mov multi-line" {
    try disassembler.assertDisassembly(
        \\mov ax, bx
        \\mov si, bx
        \\mov dh, al
        \\mov cl, 12
        \\mov cx, 12
        \\mov dx, 3948
        \\mov dx, [si]
        \\mov dx, [di]
        \\mov dx, [bp]
        \\mov dx, [bx]
        \\mov bx, [bp + di]
        \\mov al, [bx + si]
        \\mov ah, [bx + si + 4]
        \\mov al, [bx + si + 4999]
        \\mov [bx + di], cx
        \\mov [bp + si], cl
        \\mov [bp], ch
        \\mov [si + 1], cx
        \\mov ax, [bx + di - 37]
        \\mov [si - 300], cx
        \\mov dx, [bx - 32]
        \\mov [bp + di], byte 7
        \\mov [di + 901], word 347
        \\mov [bx], byte 34
        \\mov [bp + si + 1000], word 29
        \\mov [4834], byte 29
        \\mov [4834], word 29
        \\mov bp, [5]
        \\mov bx, [3458]
        \\mov ax, [2555]
        \\mov ax, [16]
        \\mov al, [16]
        \\mov [2554], ax
        \\mov [15], ax
        \\mov [15], al
    );
}

test "add" {
    try disassembler.assertDisassembly("add bx, [bx + si]");
    try disassembler.assertDisassembly("add bx, [bp]");
    try disassembler.assertDisassembly("add si, 2");
    try disassembler.assertDisassembly("add bp, 2");
    try disassembler.assertDisassembly("add cx, 8");
    try disassembler.assertDisassembly("add bx, [bp]");
    try disassembler.assertDisassembly("add cx, [bx + 2]");
    try disassembler.assertDisassembly("add bh, [bp + si + 4]");
    try disassembler.assertDisassembly("add di, [bp + di + 6]");
    try disassembler.assertDisassembly("add [bx + si], bx");
    try disassembler.assertDisassembly("add [bp], bx");
    try disassembler.assertDisassembly("add [bx + 2], cx");
    try disassembler.assertDisassembly("add [bp + si + 4], bh");
    try disassembler.assertDisassembly("add [bp + di + 6], di");
    try disassembler.assertDisassembly("add [bx], byte 34");
    try disassembler.assertDisassembly("add [bp + si + 1000], word 29");
    try disassembler.assertDisassembly("add ax, [bp]");
    try disassembler.assertDisassembly("add al, [bx + si]");
    try disassembler.assertDisassembly("add ax, bx");
    try disassembler.assertDisassembly("add al, ah");
    try disassembler.assertDisassembly("add ax, 1000");
    try disassembler.assertDisassembly("add al, 9");
}

test "sub" {
    try disassembler.assertDisassembly("sub bx, [bx + si]");
    try disassembler.assertDisassembly("sub bx, [bp]");
    try disassembler.assertDisassembly("sub si, 2");
    try disassembler.assertDisassembly("sub bp, 2");
    try disassembler.assertDisassembly("sub cx, 8");
    try disassembler.assertDisassembly("sub cx, [bx + 2]");
    try disassembler.assertDisassembly("sub bh, [bp + si + 4]");
    try disassembler.assertDisassembly("sub di, [bp + di + 6]");
    try disassembler.assertDisassembly("sub [bx + si], bx");
    try disassembler.assertDisassembly("sub [bp], bx");
    try disassembler.assertDisassembly("sub [bx + 2], cx");
    try disassembler.assertDisassembly("sub [bp + si + 4], bh");
    try disassembler.assertDisassembly("sub [bp + di + 6], di");
    try disassembler.assertDisassembly("sub [bx], byte 34");
    try disassembler.assertDisassembly("sub [bx + di], word 29");
    try disassembler.assertDisassembly("sub ax, [bp]");
    try disassembler.assertDisassembly("sub al, [bx + si]");
    try disassembler.assertDisassembly("sub ax, bx");
    try disassembler.assertDisassembly("sub al, ah");
    try disassembler.assertDisassembly("sub ax, 1000");
    try disassembler.assertDisassembly("sub al, 9");
}

test "cmp" {
    try disassembler.assertDisassembly("cmp bx, [bx + si]");
    try disassembler.assertDisassembly("cmp bx, [bp]");
    try disassembler.assertDisassembly("cmp si, 2");
    try disassembler.assertDisassembly("cmp bp, 2");
    try disassembler.assertDisassembly("cmp cx, 8");
    try disassembler.assertDisassembly("cmp bx, [bp]");
    try disassembler.assertDisassembly("cmp cx, [bx + 2]");
    try disassembler.assertDisassembly("cmp bh, [bp + si + 4]");
    try disassembler.assertDisassembly("cmp di, [bp + di + 6]");
    try disassembler.assertDisassembly("cmp [bx + si], bx");
    try disassembler.assertDisassembly("cmp [bp], bx");
    try disassembler.assertDisassembly("cmp [bx + 2], cx");
    try disassembler.assertDisassembly("cmp [bp + si + 4], bh");
    try disassembler.assertDisassembly("cmp [bp + di + 6], di");
    try disassembler.assertDisassembly("cmp [bx], byte 34");
    try disassembler.assertDisassembly("cmp [4834], word 29");
    try disassembler.assertDisassembly("cmp ax, [bp]");
    try disassembler.assertDisassembly("cmp al, [bx + si]");
    try disassembler.assertDisassembly("cmp ax, bx");
    try disassembler.assertDisassembly("cmp al, ah");
    try disassembler.assertDisassembly("cmp ax, 1000");
    try disassembler.assertDisassembly("cmp al, 9");
}
