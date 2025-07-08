const testing = @import("test.zig");

test "cmp" {
    try testing.assertInstructionDisassembly("cmp bx, [bx + si]");
    try testing.assertInstructionDisassembly("cmp bx, [bp]");
    try testing.assertInstructionDisassembly("cmp si, 2");
    try testing.assertInstructionDisassembly("cmp bp, 2");
    try testing.assertInstructionDisassembly("cmp cx, 8");
    try testing.assertInstructionDisassembly("cmp bx, [bp]");
    try testing.assertInstructionDisassembly("cmp cx, [bx + 2]");
    try testing.assertInstructionDisassembly("cmp bh, [bp + si + 4]");
    try testing.assertInstructionDisassembly("cmp di, [bp + di + 6]");
    try testing.assertInstructionDisassembly("cmp [bx + si], bx");
    try testing.assertInstructionDisassembly("cmp [bp], bx");
    try testing.assertInstructionDisassembly("cmp [bx + 2], cx");
    try testing.assertInstructionDisassembly("cmp [bp + si + 4], bh");
    try testing.assertInstructionDisassembly("cmp [bp + di + 6], di");
    try testing.assertInstructionDisassembly("cmp [bx], byte 34");
    try testing.assertInstructionDisassembly("cmp [4834], word 29");
    try testing.assertInstructionDisassembly("cmp ax, [bp]");
    try testing.assertInstructionDisassembly("cmp al, [bx + si]");
    try testing.assertInstructionDisassembly("cmp ax, bx");
    try testing.assertInstructionDisassembly("cmp al, ah");
    try testing.assertInstructionDisassembly("cmp ax, 1000");
    try testing.assertInstructionDisassembly("cmp al, 9");
}
