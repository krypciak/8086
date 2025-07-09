const std = @import("std");
const disassembler = @import("disassembler");
const testing = @import("test/test.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const str = try testing.assembleAndDisassemble(allocator, "mov ax, bx");
    defer allocator.free(str);

    std.debug.print("out:\n{s}\n", .{str});
}
