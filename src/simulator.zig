const std = @import("std");
const instruction_parser = @import("instruction_parser.zig");

const memory = @import("memory.zig");
const RegisterMemory = memory.RegisterMemory;
const RandomAccessMemory = memory.RandomAccessMemory;
const FlagsMemory = memory.FlagsMemory;

const debug = @import("main.zig").debug;

pub const SimulatorState = struct {
    at: usize = 0,
    registers: RegisterMemory = .{},
    ram: RandomAccessMemory = .{},
    flags: FlagsMemory = .{},
};

pub fn simulate(allocator: std.mem.Allocator, data: []const u8) !SimulatorState {
    const instructions = try instruction_parser.parseBinary(allocator, data);
    defer allocator.free(instructions);

    var state = SimulatorState{};

    while (state.at < instructions.len) : (state.at += 1) {
        const inst = instructions[state.at];

        switch (inst.inst) {
            .MovLike => |*o| o.execute(&state),
            .Jump => |*o| o.execute(&state),
        }
    }

    return state;
}

const disassembler = @import("disassembler.zig");
const testing = @import("test.zig");

pub fn assertSimulationToEqual(assembly: []const u8, expected: SimulatorState) !void {
    const allocator = std.testing.allocator;

    const assembled = try testing.assemble(allocator, assembly);
    defer allocator.free(assembled);

    const resulting_state = simulate(allocator, assembled);

    try std.testing.expectEqualDeep(expected, resulting_state);
}

