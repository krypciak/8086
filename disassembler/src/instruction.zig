const std = @import("std");
const mov = @import("mov.zig");
const jump = @import("jump.zig");

pub const InstructionUnion = union(Instruction.Type) {
    MovLike: mov.MovLike,
    Jump: jump.Jump,

    pub fn to_string(self: *const InstructionUnion, allocator: std.mem.Allocator) ![]const u8 {
        return switch (self.*) {
            .MovLike => |*inst| inst.to_string(allocator),
            .Jump => |*inst| inst.to_string(allocator),
        };
    }
};

pub const Instruction = struct {
    const Type = enum {
        MovLike,
        Jump,
    };

    len: usize,
    inst: InstructionUnion,
};

