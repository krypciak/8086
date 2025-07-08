const testing = @import("test.zig");

test "sub" {
    try testing.assertInstructionDisassembly("sub bx, [bx + si]");
    try testing.assertInstructionDisassembly("sub bx, [bp]");
    try testing.assertInstructionDisassembly("sub si, 2");
    try testing.assertInstructionDisassembly("sub bp, 2");
    try testing.assertInstructionDisassembly("sub cx, 8");
    try testing.assertInstructionDisassembly("sub cx, [bx + 2]");
    try testing.assertInstructionDisassembly("sub bh, [bp + si + 4]");
    try testing.assertInstructionDisassembly("sub di, [bp + di + 6]");
    try testing.assertInstructionDisassembly("sub [bx + si], bx");
    try testing.assertInstructionDisassembly("sub [bp], bx");
    try testing.assertInstructionDisassembly("sub [bx + 2], cx");
    try testing.assertInstructionDisassembly("sub [bp + si + 4], bh");
    try testing.assertInstructionDisassembly("sub [bp + di + 6], di");
    try testing.assertInstructionDisassembly("sub [bx], byte 34");
    try testing.assertInstructionDisassembly("sub [bx + di], word 29");
    try testing.assertInstructionDisassembly("sub ax, [bp]");
    try testing.assertInstructionDisassembly("sub al, [bx + si]");
    try testing.assertInstructionDisassembly("sub ax, bx");
    try testing.assertInstructionDisassembly("sub al, ah");
    try testing.assertInstructionDisassembly("sub ax, 1000");
    try testing.assertInstructionDisassembly("sub al, 9");
}
