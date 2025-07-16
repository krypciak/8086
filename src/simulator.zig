const std = @import("std");
const instruction_parser = @import("instruction_parser.zig");

const memory = @import("memory.zig");
const RegisterMemory = memory.RegisterMemory;
const RandomAccessMemory = memory.RandomAccessMemory;

const debug = @import("main.zig").debug;

pub const SimulatorState = struct {
    // registers: Re
};

pub fn simulate(allocator: std.mem.Allocator, data: []const u8) ![]const u8 {
    const instructions = try instruction_parser.parseBinary(allocator, data);
    defer allocator.free(instructions);

    // for (instructions, 0..)  |inst, i| {
    //
    // }
}
