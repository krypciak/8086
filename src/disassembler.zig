const std = @import("std");
const instruction_parser = @import("instruction_parser.zig");
const testing = @import("test.zig");

const debug = @import("main.zig").debug;

pub fn disassemble(allocator: std.mem.Allocator, data: []const u8, no_bits: bool) ![]const u8 {
    const instructions = try instruction_parser.parseBinary(allocator, data);
    defer allocator.free(instructions);

    var str_list = std.ArrayList(u8).init(allocator);

    if (!no_bits) try str_list.appendSlice("bits 16\n");

    for (instructions, 0..) |inst, i| {
        if (i != 0) {
            try str_list.append('\n');
        }

        const str = try inst.inst.toString(allocator);
        defer allocator.free(str);
        try str_list.appendSlice(str);
    }

    return str_list.toOwnedSlice();
}

pub fn assembleAndDisassemble(allocator: std.mem.Allocator, assembly: []const u8) ![]const u8 {
    if (debug) std.debug.print("\n{s}\n", .{assembly});
    const assembled = try testing.assemble(allocator, assembly);
    defer allocator.free(assembled);

    return disassemble(allocator, assembled, true);
}

pub fn assertDisassembly(assembly: []const u8) !void {
    const allocator = std.testing.allocator;
    const disassembled = try assembleAndDisassemble(allocator, assembly);
    defer allocator.free(disassembled);
    try std.testing.expectEqualStrings(assembly, disassembled);
}

pub fn assertDisassemblyToEqual(assembly: []const u8, expected: []const u8) !void {
    const allocator = std.testing.allocator;
    const disassembled = try assembleAndDisassemble(allocator, assembly);
    defer allocator.free(disassembled);
    try std.testing.expectEqualStrings(expected, disassembled);
}
