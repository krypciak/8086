const std = @import("std");
const mov = @import("mov.zig");
const jump = @import("jump.zig");

const simulator = @import("simulator.zig");
const SimulatorState = simulator.SimulatorState;

pub const InstructionUnion = union(Instruction.Type) {
    MovLike: mov.MovLike,
    Jump: jump.Jump,

    pub fn toString(self: *const InstructionUnion, allocator: std.mem.Allocator) ![]const u8 {
        return switch (self.*) {
            .MovLike => |*inst| inst.toString(allocator),
            .Jump => |*inst| inst.toString(allocator),
        };
    }

    pub fn execute(self: *const InstructionUnion, state: *SimulatorState) void {
        switch (self.*) {
            .MovLike => |*o| o.execute(state),
            .Jump => |*o| o.execute(state),
        }
    }

    pub fn estimateCycles(self: *const InstructionUnion) ?u8 {
        return switch (self.*) {
            .MovLike => |*o| o.estimateCycles(),
            .Jump => |*o| o.estimateCycles(),
        };
    }
};

pub const Instruction = struct {
    const Type = enum {
        MovLike,
        Jump,
    };

    len: u16,
    inst: InstructionUnion,
};

const testing = @import("test.zig");
const instruction_parser = @import("instruction_parser.zig");

pub fn assertEstimateCycles(assembly: []const u8, expected: u16) !void {
    const allocator = std.testing.allocator;
    const assembled = try testing.assemble(allocator, assembly);
    defer allocator.free(assembled);

    const result = try instruction_parser.parseBinary(allocator, assembled);
    defer result.deinit(allocator);

    var sum: u16 = 0;
    for (result.instructions) |inst| {
        sum += inst.inst.estimateCycles() orelse 0;
    }

    try std.testing.expectEqual(expected, sum);
}
