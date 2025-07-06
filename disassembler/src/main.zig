const std = @import("std");
const stdout = std.io.getStdOut();
const allocator = std.heap.page_allocator;
const disassembler = @import("disassembler");

pub fn main() !void {
    // try disassembler.disassemble("bits 16\nmov ax, bx");
}
