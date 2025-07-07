const std = @import("std");
const stdout = std.io.getStdOut();

pub fn disassemble(allocator: std.mem.Allocator, data: []const u8) !void {
    try stdout.writeAll("bits 16\n");
    const inst = try nextInstruction(allocator, data, 0);
    defer inst.deinit(allocator);
    try inst.print();
}

fn getRegName(val: u8, w: bool) []const u8 {
    const table_w0 = [8][]const u8{ "al", "cl", "dl", "bl", "ah", "ch", "dh", "bh" };
    const table_w1 = [8][]const u8{ "ax", "cx", "dx", "bx", "sp", "bp", "si", "di" };

    if (w) {
        return table_w1[val];
    } else {
        return table_w0[val];
    }
}

const InstructionReturn = struct {
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

// fn mov_like_parse_3(allocator: std.mem.Allocator, name: []const u8) !InstructionReturn{
//
// }

pub fn nextInstruction(allocator: std.mem.Allocator, data: []const u8, at: usize) !InstructionReturn {
    // std.debug.print("{b} {b}\n", .{ data[0], data[1] });

    const b1 = data[at];
    const b2 = data[at + 1];
    // const b3 = at + 2;
    // const b4 = at + 3;

    const mov_type_1 = b1 & 0b11111100 == 0b10001000;
    const mov_type_2 = b1 & 0b11111110 == 0b11000110;
    if (mov_type_1 or mov_type_2) { // mov
        const w: bool = (b1 & 0b00000001) == 0b00000001;

        const mod: u8 = (b2 & 0b11000000) >> 6;

        const reg = (b2 & 0b00111000) >> 3;
        const rm = b2 & 0b00000111;

        // std.debug.print("mov, w: {}, mod: {}, reg: {}, rm: {}\n", .{ w, mod, reg, rm });

        if (mod == 0b11) { // mov register-to-register
            std.debug.assert(mov_type_1);
            const str = try std.fmt.allocPrint(allocator, "mov {s}, {s}", .{ getRegName(rm, w), getRegName(reg, w) });
            return InstructionReturn{ .len = 2, .str = str };
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

        if (mov_type_1) part1 = getRegName(reg, w);
        if (mod == 0b00) {
            if (rm == 0b110) {
                len = 4;
                const b3: u16 = data[at + 2];
                const b4: u16 = data[at + 3];
                const displacement: u16 = (b4 << 8) + b3;
                part2 = try std.fmt.allocPrint(allocator, "[{d}]", .{displacement});
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

        if (mov_type_2) {
            part1 = part2;
            free_part1 = true;

            var value: u16 = undefined;
            if (rm == 0b11) {
                const b3: u16 = data[at + 2];
                value = b3;
            } else {
                const b5 = data[at + 4];
                value = b5;
                if (w) {
                    const b6: u16 = data[at + 5];
                    value += b6 << 8;
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

        return InstructionReturn{ .len = len, .str = try std.fmt.allocPrint(allocator, "mov {s}, {s}", .{ part1, part2 }) };
    } else if (b1 & 0b11110000 == 0b10110000) { // mov 8-bit immediate-to-register
        const w: bool = (b1 & 0b00001000) == 0b00001000;
        const reg = b1 & 0b00000111;

        var value: u16 = b2;
        if (w) {
            const b3: u16 = data[at + 2];
            value += b3 << 8;
        }
        return InstructionReturn{ .len = if (w) 3 else 2, .str = try std.fmt.allocPrint(allocator, "mov {s}, {d}", .{ getRegName(reg, w), value }) };
    } else if (b1 & 0b11111110 == 0b10100000 or b1 & 0b11111110 == 0b10100010) {
        const w: bool = (b1 & 0b00000001) == 1;

        var value: u16 = b2;
        if (w) {
            const b3: u16 = data[at + 2];
            value += b3 << 8;
        }

        var part1: []const u8 = if (w) "ax" else "al";
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
    } else unreachable;
}
