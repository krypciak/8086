const std = @import("std");
const disassembler = @import("disassembler.zig");
const testing = @import("test.zig");

pub const debug = false;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const str = try testing.assembleAndDisassemble(allocator, "mov ax, bx");
    defer allocator.free(str);

    std.debug.print("out:\n{s}\n", .{str});
}
