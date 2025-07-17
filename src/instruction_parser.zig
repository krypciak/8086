const std = @import("std");
const ArrayList = std.ArrayList;

const memory = @import("memory.zig");
const mov = @import("mov.zig");
const jump = @import("jump.zig");
const instruction_parser = @import("instruction_parser.zig");

const instruciton = @import("instruction.zig");
const Instruction = instruciton.Instruction;

const debug = @import("main.zig").debug;

pub fn getValue(data: []const u8, at: usize, w: bool) u16 {
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
        return mov.movLike(data, at, .Mov, true, false, .No);
    } else if (b1 & 0b11111110 == 0b11000110) {
        return mov.movLike(data, at, .Mov, false, false, .No);
    } else if (b1 & 0b11110000 == 0b10110000) {
        return mov.movImmediateToRegister(data, at);
    } else if (b1 & 0b11111110 == 0b10100000 or b1 & 0b11111110 == 0b10100010) {
        return mov.movMemoryToAccumulator(data, at);
    } else if (b1 == 0b10001110) {
        return mov.movLike(data, at, .Mov, true, false, .Reverse);
    } else if (b1 == 0b10001100) {
        return mov.movLike(data, at, .Mov, true, false, .Normal);
    } else if (b1 & 0b11111100 == 0b00000000) {
        return mov.movLike(data, at, .Add, true, false, .No);
    } else if (b1 & 0b11111100 == 0b10000000) {
        return mov.movLike(data, at, .Add, false, true, .No);
    } else if (b1 & 0b11111110 == 0b00000100) {
        return mov.arithmeticImmediateFromAccumulator(data, at, .Add);
    } else if (b1 & 0b11111100 == 0b00101000) {
        return mov.movLike(data, at, .Sub, true, false, .No);
    } else if (b1 & 0b11111110 == 0b00101100) {
        return mov.arithmeticImmediateFromAccumulator(data, at, .Sub);
    } else if (b1 & 0b11111100 == 0b00111000) {
        return mov.movLike(data, at, .Cmp, true, false, .No);
    } else if (b1 & 0b11111110 == 0b00111100) {
        return mov.arithmeticImmediateFromAccumulator(data, at, .Cmp);
    } else if (b1 == 0b01110100) {
        return jump.conditionalJump(data, at, .je);
    } else if (b1 == 0b01111100) {
        return jump.conditionalJump(data, at, .jl);
    } else if (b1 == 0b01111110) {
        return jump.conditionalJump(data, at, .jle);
    } else if (b1 == 0b01110010) {
        return jump.conditionalJump(data, at, .jb);
    } else if (b1 == 0b01110110) {
        return jump.conditionalJump(data, at, .jbe);
    } else if (b1 == 0b01111010) {
        return jump.conditionalJump(data, at, .jp);
    } else if (b1 == 0b01110000) {
        return jump.conditionalJump(data, at, .jo);
    } else if (b1 == 0b01111000) {
        return jump.conditionalJump(data, at, .js);
    } else if (b1 == 0b01110101) {
        return jump.conditionalJump(data, at, .jne);
    } else if (b1 == 0b01111101) {
        return jump.conditionalJump(data, at, .jnl);
    } else if (b1 == 0b01111111) {
        return jump.conditionalJump(data, at, .jnle);
    } else if (b1 == 0b01110011) {
        return jump.conditionalJump(data, at, .jnb);
    } else if (b1 == 0b01110111) {
        return jump.conditionalJump(data, at, .jnbe);
    } else if (b1 == 0b01111011) {
        return jump.conditionalJump(data, at, .jnp);
    } else if (b1 == 0b01110001) {
        return jump.conditionalJump(data, at, .jno);
    } else if (b1 == 0b01111001) {
        return jump.conditionalJump(data, at, .jns);
    } else if (b1 == 0b11100010) {
        return jump.conditionalJump(data, at, .loop);
    } else if (b1 == 0b11100001) {
        return jump.conditionalJump(data, at, .loopz);
    } else if (b1 == 0b011100000) {
        return jump.conditionalJump(data, at, .loopnz);
    } else if (b1 == 0b11100011) {
        return jump.conditionalJump(data, at, .jcxz);
    } else unreachable;
}

pub const ParseBinaryResult = struct {
    instructions: []const Instruction,
    instructionMappings: []u16,

    pub fn deinit(self: *const ParseBinaryResult, allocator: std.mem.Allocator) void {
        allocator.free(self.instructions);
        allocator.free(self.instructionMappings);
    }
};

pub fn parseBinary(allocator: std.mem.Allocator, data: []const u8) !ParseBinaryResult {
    var list = ArrayList(Instruction).init(allocator);
    var mappings = try allocator.alloc(u16, data.len);
    @memset(mappings, 0xFF);

    var at: u16 = 0;
    while (at < data.len) {
        const inst = try instruction_parser.nextInstruction(data, at);
        std.debug.assert(list.items.len <= std.math.maxInt(u16));
        mappings[at] = @truncate(list.items.len);
        try list.append(inst);
        at += inst.len;
    }
    if (at != data.len) {
        std.debug.print("at: {d}, data.len: {d}\n", .{ at, data.len });
        std.debug.assert(false);
    }

    return .{
        .instructions = try list.toOwnedSlice(),
        .instructionMappings = mappings,
    };
}
