const std = @import("std");
const stdout = std.io.getStdOut();

pub const debug = false;

pub fn disassemble(allocator: std.mem.Allocator, data: []const u8) !void {
    try stdout.writeAll("bits 16\n");
    const inst = try nextInstruction(allocator, data, 0);
    defer inst.deinit(allocator);
    try inst.print();
}

fn get_reg_name(val: u8, w: bool) []const u8 {
    const table_w0 = [8][]const u8{ "al", "cl", "dl", "bl", "ah", "ch", "dh", "bh" };
    const table_w1 = [8][]const u8{ "ax", "cx", "dx", "bx", "sp", "bp", "si", "di" };

    if (w) {
        return table_w1[val];
    } else {
        return table_w0[val];
    }
}

pub const InstructionReturn = struct {
    len: usize,
    str: []u8,

    fn print(self: *const InstructionReturn) !void {
        try stdout.writeAll(self.str);
        try stdout.writeAll("\n");
    }

    pub fn deinit(self: *const InstructionReturn, allocator: std.mem.Allocator) void {
        allocator.free(self.str);
    }
};

fn get_value(data: []const u8, at: usize, w: bool) u16 {
    const b1 = data[at];
    var value: u16 = b1;
    if (w) {
        const b2: u16 = data[at + 1];
        value += b2 << 8;
    }
    return value;
}

fn mov_like(allocator: std.mem.Allocator, data: []const u8, at: usize, name: []const u8, first_type: bool, check_sign: bool) !InstructionReturn {
    var new_name = name;

    const b1 = data[at];
    const b2 = data[at + 1];

    const w: bool = (b1 & 0b00000001) == 0b00000001;

    const mod: u8 = (b2 & 0b11000000) >> 6;

    const reg = (b2 & 0b00111000) >> 3;
    const rm = b2 & 0b00000111;

    if (!first_type) {
        if (reg == 0b101) {
            std.debug.assert(std.mem.eql(u8, name, "add"));
            new_name = "sub";
        } else if (reg == 0b000) {
            std.debug.assert(std.mem.eql(u8, name, "mov") or std.mem.eql(u8, name, "add"));
        } else if (reg == 0b111) {
            std.debug.assert(std.mem.eql(u8, name, "add"));
            new_name = "cmp";
        }
    }
    // std.debug.print("new_name: {s}, w: {}, mod: {}, reg: {}, rm: {}\n", .{ new_name, w, mod, reg, rm });

    if (mod == 0b11) { // register-to-register
        if (check_sign) {
            const s: bool = (b1 & 0b00000010) == 0b00000010;
            std.debug.assert(s);
            const value = get_value(data, at + 2, false);
            return InstructionReturn{ .len = 2, .str = try std.fmt.allocPrint(allocator, "{s} {s}, {d}", .{ new_name, get_reg_name(rm, w), value }) };
        } else {
            std.debug.assert(first_type);
            return InstructionReturn{ .len = 2, .str = try std.fmt.allocPrint(allocator, "{s} {s}, {s}", .{ new_name, get_reg_name(rm, w), get_reg_name(reg, w) }) };
        }
    }

    const register_table = [8][2][2]u8{
        .{ .{ 'b', 'x' }, .{ 's', 'i' } },
        .{ .{ 'b', 'x' }, .{ 'd', 'i' } },
        .{ .{ 'b', 'p' }, .{ 's', 'i' } },
        .{ .{ 'b', 'p' }, .{ 'd', 'i' } },
        .{ .{ 's', 'i' }, .{ '-', '-' } },
        .{ .{ 'd', 'i' }, .{ '-', '-' } },
        .{ .{ 'b', 'p' }, .{ '-', '-' } },
        .{ .{ 'b', 'x' }, .{ '-', '-' } },
    };
    const r1 = register_table[rm][0];
    const r2 = register_table[rm][1];

    var part1: []const u8 = undefined;
    var part2: []const u8 = undefined;
    var free_part1 = false;
    var free_part2 = true;
    defer if (free_part1) allocator.free(part1);
    defer if (free_part2) allocator.free(part2);

    var len: usize = undefined;

    if (first_type) part1 = get_reg_name(reg, w);
    if (mod == 0b00) {
        if (rm == 0b110) {
            len = 4;
            const value: u16 = get_value(data, at + 2, true);
            part2 = try std.fmt.allocPrint(allocator, "[{d}]", .{value});
        } else {
            len = 2;
            if (r2[0] == '-') {
                part2 = try std.fmt.allocPrint(allocator, "[{s}]", .{r1});
            } else {
                part2 = try std.fmt.allocPrint(allocator, "[{s} + {s}]", .{ r1, r2 });
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
            part2 = try std.fmt.allocPrint(allocator, "[{s}]", .{r1});
        } else {
            // std.debug.assert(r2[0] != '-');
            const sign: u8 = if (displacement >= 0) '+' else '-';
            if (r2[0] == '-') {
                part2 = try std.fmt.allocPrint(allocator, "[{s} {c} {d}]", .{ r1, sign, @abs(displacement) });
            } else {
                part2 = try std.fmt.allocPrint(allocator, "[{s} + {s} {c} {d}]", .{ r1, r2, sign, @abs(displacement) });
            }
        }
    }

    if (!first_type) {
        part1 = part2;
        free_part1 = true;

        var value: u16 = undefined;
        if (rm == 0b11) {
            const b3: u16 = data[at + 2];
            value = b3;
        } else {
            const s_flag: bool = (b1 & 0b00000010) == 0b00000010;
            const wide = w and (!check_sign or !s_flag);

            if (mod == 0b00 and rm != 0b110) {
                value = get_value(data, at + 2, wide);
                len = @max(len, 3 + @as(usize, @intFromBool(wide)));
            } else {
                value = get_value(data, at + 4, wide);
                len = @max(len, 5 + @as(usize, @intFromBool(wide)));
            }
        }
        part2 = try std.fmt.allocPrint(allocator, "{s} {d}", .{ if (w) "word" else "byte", value });
    } else if ((b1 & 0b00000010) != 0b00000010) { // check d
        const temp = part2;
        part2 = part1;
        part1 = temp;
        free_part1 = true;
        free_part2 = false;
    }

    return InstructionReturn{ .len = len, .str = try std.fmt.allocPrint(allocator, "{s} {s}, {s}", .{ new_name, part1, part2 }) };
}

fn arithmetic_immediate_from_accumulator(allocator: std.mem.Allocator, data: []const u8, at: usize, name: []const u8) !InstructionReturn {
    const b1 = data[at];
    const w: bool = (b1 & 0b00000001) == 1;
    const value = get_value(data, at + 1, w);
    return InstructionReturn{ .len = if (w) 3 else 2, .str = try std.fmt.allocPrint(allocator, "{s} {s}, {d}", .{ name, get_reg_name(0, w), value }) };
}

fn conditional_jump(allocator: std.mem.Allocator, data: []const u8, at: usize, name: []const u8) !InstructionReturn {
    const b2: i8 = @bitCast(data[at + 1]);
    return InstructionReturn{ .len = 2, .str = try std.fmt.allocPrint(allocator, "{s} {d}", .{ name, b2 }) };
}

pub fn nextInstruction(allocator: std.mem.Allocator, data: []const u8, at: usize) !InstructionReturn {
    if (debug) {
        for (data) |byte| {
            std.debug.print("{b:->8} ", .{byte});
        }
        std.debug.print("\n", .{});
        for (data) |byte| {
            std.debug.print("{d:->8} ", .{byte});
        }
        std.debug.print("\n", .{});
    }

    const b1 = data[at];

    if (b1 & 0b11111100 == 0b10001000) {
        return mov_like(allocator, data, at, "mov", true, false);
    } else if (b1 & 0b11111110 == 0b11000110) {
        return mov_like(allocator, data, at, "mov", false, false);
    } else if (b1 & 0b11110000 == 0b10110000) { // mov immediate-to-register
        const w: bool = (b1 & 0b00001000) == 0b00001000;
        const reg = b1 & 0b00000111;

        const value: u16 = get_value(data, at + 1, w);
        return InstructionReturn{ .len = if (w) 3 else 2, .str = try std.fmt.allocPrint(allocator, "mov {s}, {d}", .{ get_reg_name(reg, w), value }) };
    } else if (b1 & 0b11111110 == 0b10100000 or b1 & 0b11111110 == 0b10100010) {
        const w: bool = (b1 & 0b00000001) == 1;

        const value: u16 = get_value(data, at + 1, w);

        var part1: []const u8 = get_reg_name(0, w);
        var part2: []const u8 = try std.fmt.allocPrint(allocator, "[{d}]", .{value});
        var free_part1 = false;
        var free_part2 = true;
        defer if (free_part1) allocator.free(part1);
        defer if (free_part2) allocator.free(part2);

        if (b1 & 0b11111110 == 0b10100010) {
            const temp = part2;
            part2 = part1;
            part1 = temp;
            free_part1 = true;
            free_part2 = false;
        }
        return InstructionReturn{ .len = 3, .str = try std.fmt.allocPrint(allocator, "mov {s}, {s}", .{ part1, part2 }) };
    } else if (b1 & 0b11111100 == 0b00000000) {
        return mov_like(allocator, data, at, "add", true, false);
    } else if (b1 & 0b11111100 == 0b10000000) {
        return mov_like(allocator, data, at, "add", false, true);
    } else if (b1 & 0b11111110 == 0b00000100) {
        return arithmetic_immediate_from_accumulator(allocator, data, at, "add");
    } else if (b1 & 0b11111100 == 0b00101000) {
        return mov_like(allocator, data, at, "sub", true, false);
    } else if (b1 & 0b11111110 == 0b00101100) {
        return arithmetic_immediate_from_accumulator(allocator, data, at, "sub");
    } else if (b1 & 0b11111100 == 0b00111000) {
        return mov_like(allocator, data, at, "cmp", true, false);
    } else if (b1 & 0b11111110 == 0b00111100) {
        return arithmetic_immediate_from_accumulator(allocator, data, at, "cmp");
    } else if (b1 == 0b01110100) {
        return conditional_jump(allocator, data, at, "je");
    } else if (b1 == 0b01111100) {
        return conditional_jump(allocator, data, at, "jl");
    } else if (b1 == 0b01111110) {
        return conditional_jump(allocator, data, at, "jle");
    } else if (b1 == 0b01110010) {
        return conditional_jump(allocator, data, at, "jb");
    } else if (b1 == 0b01110110) {
        return conditional_jump(allocator, data, at, "jbe");
    } else if (b1 == 0b01111010) {
        return conditional_jump(allocator, data, at, "jp");
    } else if (b1 == 0b01110000) {
        return conditional_jump(allocator, data, at, "jo");
    } else if (b1 == 0b01111000) {
        return conditional_jump(allocator, data, at, "js");
    } else if (b1 == 0b01110101) {
        return conditional_jump(allocator, data, at, "jne");
    } else if (b1 == 0b01111101) {
        return conditional_jump(allocator, data, at, "jnl");
    } else if (b1 == 0b01111111) {
        return conditional_jump(allocator, data, at, "jnle");
    } else if (b1 == 0b01110011) {
        return conditional_jump(allocator, data, at, "jnb");
    } else if (b1 == 0b01110111) {
        return conditional_jump(allocator, data, at, "jnbe");
    } else if (b1 == 0b01111011) {
        return conditional_jump(allocator, data, at, "jnp");
    } else if (b1 == 0b01110001) {
        return conditional_jump(allocator, data, at, "jno");
    } else if (b1 == 0b01111001) {
        return conditional_jump(allocator, data, at, "jns");
    } else if (b1 == 0b11100010) {
        return conditional_jump(allocator, data, at, "loop");
    } else if (b1 == 0b11100001) {
        return conditional_jump(allocator, data, at, "loopz");
    } else if (b1 == 0b011100000) {
        return conditional_jump(allocator, data, at, "loopnz");
    } else if (b1 == 0b11100011) {
        return conditional_jump(allocator, data, at, "jcxz");
    } else unreachable;
}
