const std = @import("std");
const instruction_parser = @import("instruction_parser.zig");

const memory = @import("memory.zig");
const RegisterMemory = memory.RegisterMemory;
const RandomAccessMemory = memory.RandomAccessMemory;
const FlagsMemory = memory.FlagsMemory;

const debug = @import("main.zig").debug;

pub const SimulatorState = struct {
    registers: RegisterMemory = .{},
    ram: RandomAccessMemory = .{},
    flags: FlagsMemory = .{},
};

pub fn simulate(allocator: std.mem.Allocator, data: []const u8, state: *SimulatorState) !void {
    const result = try instruction_parser.parseBinary(allocator, data);
    defer result.deinit(allocator);

    while (state.registers.ip < data.len) {
        const inst_index = result.instructionMappings[state.registers.ip];
        std.debug.assert(inst_index != 0xFFFF);
        const inst = result.instructions[inst_index];

        if (debug) {
            const str = try inst.inst.toString(allocator);
            defer allocator.free(str);
            std.debug.print("\n{s} ;", .{str});
        }

        const prev_ip = state.registers.ip;
        const prev_flags = state.flags;

        state.registers.ip += inst.len;

        inst.inst.execute(state);

        if (debug) {
            std.debug.print(" ip:0x{x}->0x{x}", .{ prev_ip, state.registers.ip });

            if (!std.meta.eql(prev_flags, state.flags)) {
                const prev_str = try prev_flags.toString(allocator);
                const curr_str = try state.flags.toString(allocator);
                defer allocator.free(prev_str);
                defer allocator.free(curr_str);
                std.debug.print(" flags:{s}->{s}", .{ prev_str, curr_str });
            }
        }
    }
}

const disassembler = @import("disassembler.zig");
const testing = @import("test.zig");

pub fn assertSimulationToEqualWithState(assembly: []const u8, state: *SimulatorState, expected: SimulatorState) !void {
    state.registers.ip = 0;
    const allocator = std.testing.allocator;

    const assembled = try testing.assemble(allocator, assembly);
    defer allocator.free(assembled);

    try simulate(allocator, assembled, state);

    try std.testing.expectEqualDeep(expected.registers, state.registers);
    try std.testing.expectEqualDeep(expected.flags, state.flags);
}

pub fn assertSimulationToEqual(assembly: []const u8, expected: SimulatorState) !void {
    var state = SimulatorState{};
    try assertSimulationToEqualWithState(assembly, &state, expected);
}
