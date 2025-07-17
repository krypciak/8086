const std = @import("std");

const memory = @import("memory.zig");
const RegisterMemory = memory.RegisterMemory;

const instruciton = @import("instruction.zig");
const Instruction = instruciton.Instruction;

const instruction_parser = @import("instruction_parser.zig");
const getValue = instruction_parser.getValue;

const simulator = @import("simulator.zig");
const SimulatorState = simulator.SimulatorState;

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
        return std.fmt.allocPrint(allocator, "{s}", .{getMovRegName(self.register, self.wide)});
    }

    pub fn getValue(self: *const RegisterAddress, state: *const SimulatorState) u16 {
        return state.registers.getValue(self.register, self.wide);
    }

    pub fn setValue(self: *const RegisterAddress, state: *SimulatorState, value: u16) void {
        state.registers.setValue(self.register, self.wide, value);
    }
};

pub const MemoryAddress = struct {
    displacement: i16 = 0,
    reg1: ?RegisterMemory.RegisterWord = null,
    reg2: ?RegisterMemory.RegisterWord = null,
    wide: bool,

    pub fn toString(self: *const MemoryAddress, allocator: std.mem.Allocator) ![]const u8 {
        if (self.reg1) |reg1| {
            const sign: u8 = if (self.displacement >= 0) '+' else '-';

            const r1 = reg1.toString();
            if (self.reg2) |reg2| {
                const r2 = reg2.toString();
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

    fn calculateAddress(self: *const MemoryAddress, state: *const SimulatorState) u16 {
        var address: i16 = self.displacement;
        if (self.reg1) |reg1| {
            address += @intCast(state.registers.getValueWord(reg1));

            if (self.reg2) |reg2| {
                address += @intCast(state.registers.getValueWord(reg2));
            }
        }
        std.debug.assert(address >= 0);
        return @intCast(address);
    }

    pub fn getValue(self: *const MemoryAddress, state: *const SimulatorState) u16 {
        const address = self.calculateAddress(state);
        return state.ram.getValue(address, self.wide);
    }

    pub fn setValue(self: *const MemoryAddress, state: *SimulatorState, value: u16) void {
        const address = self.calculateAddress(state);
        state.ram.setValue(address, self.wide, value);
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

    pub fn getValue(self: *const AddressOrValue, state: *const SimulatorState) u16 {
        return switch (self.*) {
            .Value => |*v| v.value,
            .RegisterAddress => |*reg| reg.getValue(state),
            .MemoryAddress => |*mem| mem.getValue(state),
        };
    }

    pub fn setValue(self: *const AddressOrValue, state: *SimulatorState, value: u16) void {
        switch (self.*) {
            .Value => unreachable,
            .RegisterAddress => |*reg| reg.setValue(state, value),
            .MemoryAddress => |*mem| mem.setValue(state, value),
        }
    }

    pub fn isWide(self: *const AddressOrValue) bool {
        return switch (self.*) {
            .Value => unreachable,
            .RegisterAddress => |*reg| reg.wide,
            .MemoryAddress => |*mem| mem.wide,
        };
    }
};

fn getMovRegName(val: u8, w: bool) []const u8 {
    if (w) {
        return @as(RegisterMemory.RegisterWord, @enumFromInt(val)).toString();
    } else {
        return @as(RegisterMemory.RegisterByte, @enumFromInt(val)).toString();
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

    fn performMathOperation(self: *const MovLike, comptime T: type, to_value: T, from_value: T, state: *SimulatorState) T {
        var new_value: T = undefined;

        const sign_mask = if (T == u16) 0x8000 else 0x80;

        switch (self.type) {
            .Add => {
                const r = @addWithOverflow(to_value, from_value);
                state.flags.carry = r[1] == 1;
                state.flags.auxiliary = ((to_value & 0xF) + (from_value & 0xF)) > 0xF;
                new_value = r[0];
            },
            .Sub, .Cmp => {
                const r = @subWithOverflow(to_value, from_value);
                state.flags.carry = r[1] == 1;
                state.flags.auxiliary = (to_value & 0xF) < (from_value & 0xF);
                new_value = r[0];
            },
            else => unreachable,
        }

        // std.debug.print("{}, type: {}, to_value: {}, from_value: {}, result: {}\n", .{ self.type, T, to_value, from_value, new_value });

        state.flags.zero = new_value == 0;
        state.flags.parity = @popCount(@as(u8, @truncate(new_value))) & 1 == 0;

        state.flags.sign = new_value & sign_mask == sign_mask;
        state.flags.overflow = blk: {
            const sign_to = to_value & sign_mask;
            const sign_from = from_value & sign_mask;
            const sign_res = new_value & sign_mask;

            switch (self.type) {
                .Add => {
                    break :blk (sign_to == sign_from) and (sign_res != sign_to);
                },
                .Sub, .Cmp => {
                    break :blk (sign_to != sign_from) and (sign_res != sign_to);
                },
                else => break :blk false,
            }
        };

        return new_value;
    }

    pub fn execute(self: *const MovLike, state: *SimulatorState) void {
        const fromValue = self.from.getValue(state);

        if (self.type == .Mov) {
            self.to.setValue(state, fromValue);
        } else {
            const to_value = self.to.getValue(state);
            const w = self.to.isWide();

            const new_value = blk: {
                if (w) {
                    break :blk self.performMathOperation(u16, to_value, fromValue, state);
                } else {
                    std.debug.assert(to_value <= std.math.maxInt(u8));
                    std.debug.assert(fromValue <= std.math.maxInt(u8));
                    break :blk self.performMathOperation(u8, @truncate(to_value), @truncate(fromValue), state);
                }
            };

            if (self.type != .Cmp) {
                self.to.setValue(state, new_value);
            }
        }
    }
};

pub const MovLikeSegmentType = enum {
    No,
    Normal,
    Reverse,
};

pub fn movLike(data: []const u8, at: usize, comptime mov_type: MovLike.Type, comptime first_type: bool, comptime check_sign: bool, comptime segment_registers: MovLikeSegmentType) !Instruction {
    const b1 = data[at];
    const b2 = data[at + 1];

    var w: bool = (b1 & 0b00000001) == 0b00000001;

    const mod: u8 = (b2 & 0b11000000) >> 6;

    var reg = (b2 & 0b00111000) >> 3;
    if (segment_registers != .No) {
        reg = @intFromEnum(RegisterMemory.RegisterWord.ES) + reg;
        w = true;
    }
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

    var to: AddressOrValue = undefined;
    var from: AddressOrValue = undefined;
    var len: u16 = undefined;

    if (mod == 0b11) { // register-to-register
        to = .{ .RegisterAddress = .{ .register = rm, .wide = w } };
        if (check_sign) {
            const s_flag: bool = (b1 & 0b00000010) == 0b00000010;
            const wide = w and !s_flag;

            const raw_value = getValue(data, at + 2, wide);

            if (s_flag and w) {
                from = .{ .Value = .{ .value = @bitCast(@as(i16, @as(i8, @bitCast(@as(u8, @truncate(raw_value)))))) } };
                len = 3;
            } else {
                from = .{ .Value = .{ .value = @truncate(raw_value) } };
                len = if (wide) 4 else 3;
            }
        } else {
            std.debug.assert(first_type);

            from = .{ .RegisterAddress = .{ .register = reg, .wide = w } };
            len = 2;
        }
    } else {
        const EMPTY = RegisterMemory.RegisterWord.SS;
        const register_table = [8][2]RegisterMemory.RegisterWord{
            .{ .BX, .SI },
            .{ .BX, .DI },
            .{ .BP, .SI },
            .{ .BP, .DI },
            .{ .SI, EMPTY },
            .{ .DI, EMPTY },
            .{ .BP, EMPTY },
            .{ .BX, EMPTY },
        };
        const r1 = register_table[rm][0];
        const r2 = register_table[rm][1];

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

        if (first_type) {
            to = .{ .RegisterAddress = .{ .register = reg, .wide = w } };
        } else {
            to = from;

            var value: u16 = undefined;
            if (rm == 0b11) {
                const b3: u16 = data[at + 2];
                value = b3;
                len = 3;
            } else {
                const s_flag: bool = (b1 & 0b00000010) == 0b00000010;
                const wide = w and (!check_sign or !s_flag);

                if (mod == 0b00) {
                    if (rm == 0b110) {
                        value = getValue(data, at + 4, wide);
                        len = 5 + @as(u16, @intFromBool(wide));
                    } else {
                        value = getValue(data, at + 2, wide);
                        len = 3 + @as(u16, @intFromBool(wide));
                    }
                } else {
                    const mod_offset: u16 = if (mod == 0b01) 1 else 2;
                    value = getValue(data, at + 2 + mod_offset, wide);
                    len = 2 + mod_offset + 1 + @as(u16, @intFromBool(wide));
                }
            }
            from = .{ .Value = .{ .value = value } };
        }
    }

    if (first_type) {
        const is_d_set = mod != 0b11 and (b1 & 0b00000010) != 0b00000010;
        if (segment_registers == .Reverse or is_d_set) {
            const temp = from;
            from = to;
            to = temp;
        }
    }

    return Instruction{ .len = len, .inst = .{ .MovLike = .{ .type = new_mov_type, .from = from, .to = to } } };
}

pub fn arithmeticImmediateFromAccumulator(data: []const u8, at: usize, comptime movType: MovLike.Type) Instruction {
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
