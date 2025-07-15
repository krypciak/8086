const std = @import("std");
const instruction_parser = @import("instruction_parser.zig");

const debug = @import("main.zig").debug;

comptime {
    _ = @import("test.zig");
}

pub fn disassemble(allocator: std.mem.Allocator, data: []const u8, no_bits: bool) ![]const u8 {
    const instructions = try instruction_parser.parseBinary(allocator, data);
    defer allocator.free(instructions);

    var str_list = std.ArrayList(u8).init(allocator);

    if (!no_bits) try str_list.appendSlice("bits 16\n");

    for (instructions, 0..)  |inst, i| {
        if (i != 0) {
            try str_list.append('\n');
        }

        const str = try inst.inst.to_string(allocator);
        defer allocator.free(str);
        try str_list.appendSlice(str);
    }

    return str_list.toOwnedSlice();
}
