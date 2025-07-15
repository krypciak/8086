const std = @import("std");
const memory = @import("memory.zig");
const Instruction = @import("instruction.zig").Instruction;
const mov = @import("mov.zig");
const jump = @import("jump.zig");

pub const debug = false;

comptime {
    _ = @import("test.zig");
}

pub fn disassemble(allocator: std.mem.Allocator, data: []const u8, no_bits: bool) ![]const u8 {
    var instruction_list = std.ArrayList(u8).init(allocator);

    if (!no_bits) try instruction_list.appendSlice("bits 16\n");

    var at: usize = 0;
    while (true) {
        const inst = try nextInstruction(data, at);
        const str = try inst.inst.to_string(allocator);
        defer allocator.free(str);
        try instruction_list.appendSlice(str);
        if (debug) std.debug.print("at: {d}, len: {d}, inst: {s}\n", .{ at, inst.len, str });
        at += inst.len;

        if (at < data.len) {
            try instruction_list.append('\n');
        } else break;
    }

    return instruction_list.toOwnedSlice();
}

pub fn get_value(data: []const u8, at: usize, w: bool) u16 {
    const b1 = data[at];
    var value: u16 = b1;
    if (w) {
        const b2: u16 = data[at + 1];
        value += b2 << 8;
    }
    return value;
}

fn nextInstruction(data: []const u8, at: usize) !Instruction {
    if (debug) {
        const possible_slice = data[at..(if (data.len - at > 6) at + 6 else data.len)];
        for (possible_slice) |byte| {
            std.debug.print("{b:->8} ", .{byte});
        }
        std.debug.print("\n", .{});
        for (possible_slice) |byte| {
            std.debug.print("{d:->8} ", .{byte});
        }
        std.debug.print("\n", .{});
    }

    const b1 = data[at];

    if (b1 & 0b11111100 == 0b10001000) {
        return mov.mov_like(data, at, .Mov, true, false);
    } else if (b1 & 0b11111110 == 0b11000110) {
        return mov.mov_like(data, at, .Mov, false, false);
    } else if (b1 & 0b11110000 == 0b10110000) {
        return mov.mov_immediate_to_register(data, at);
    } else if (b1 & 0b11111110 == 0b10100000 or b1 & 0b11111110 == 0b10100010) {
        return mov.mov_memory_to_accumulator(data,at);
    } else if (b1 & 0b11111100 == 0b00000000) {
        return mov.mov_like(data, at, .Add, true, false);
    } else if (b1 & 0b11111100 == 0b10000000) {
        return mov.mov_like(data, at, .Add, false, true);
    } else if (b1 & 0b11111110 == 0b00000100) {
        return mov.arithmetic_immediate_from_accumulator(data, at, .Add);
    } else if (b1 & 0b11111100 == 0b00101000) {
        return mov.mov_like(data, at, .Sub, true, false);
    } else if (b1 & 0b11111110 == 0b00101100) {
        return mov.arithmetic_immediate_from_accumulator(data, at, .Sub);
    } else if (b1 & 0b11111100 == 0b00111000) {
        return mov.mov_like(data, at, .Cmp, true, false);
    } else if (b1 & 0b11111110 == 0b00111100) {
        return mov.arithmetic_immediate_from_accumulator(data, at, .Cmp);
    } else if (b1 == 0b01110100) {
        return jump.conditional_jump(data, at, .je);
    } else if (b1 == 0b01111100) {
        return jump.conditional_jump(data, at, .jl);
    } else if (b1 == 0b01111110) {
        return jump.conditional_jump(data, at, .jle);
    } else if (b1 == 0b01110010) {
        return jump.conditional_jump(data, at, .jb);
    } else if (b1 == 0b01110110) {
        return jump.conditional_jump(data, at, .jbe);
    } else if (b1 == 0b01111010) {
        return jump.conditional_jump(data, at, .jp);
    } else if (b1 == 0b01110000) {
        return jump.conditional_jump(data, at, .jo);
    } else if (b1 == 0b01111000) {
        return jump.conditional_jump(data, at, .js);
    } else if (b1 == 0b01110101) {
        return jump.conditional_jump(data, at, .jne);
    } else if (b1 == 0b01111101) {
        return jump.conditional_jump(data, at, .jnl);
    } else if (b1 == 0b01111111) {
        return jump.conditional_jump(data, at, .jnle);
    } else if (b1 == 0b01110011) {
        return jump.conditional_jump(data, at, .jnb);
    } else if (b1 == 0b01110111) {
        return jump.conditional_jump(data, at, .jnbe);
    } else if (b1 == 0b01111011) {
        return jump.conditional_jump(data, at, .jnp);
    } else if (b1 == 0b01110001) {
        return jump.conditional_jump(data, at, .jno);
    } else if (b1 == 0b01111001) {
        return jump.conditional_jump(data, at, .jns);
    } else if (b1 == 0b11100010) {
        return jump.conditional_jump(data, at, .loop);
    } else if (b1 == 0b11100001) {
        return jump.conditional_jump(data, at, .loopz);
    } else if (b1 == 0b011100000) {
        return jump.conditional_jump(data, at, .loopnz);
    } else if (b1 == 0b11100011) {
        return jump.conditional_jump(data, at, .jcxz);
    } else unreachable;
}
