const testing = @import("test.zig");

test "add" {
    try testing.assertInstructionDisassembly("add bx, [bx+si]");
    try testing.assertInstructionDisassembly("add bx, [bp]");
    try testing.assertInstructionDisassembly("add si, 2");
    try testing.assertInstructionDisassembly("add bp, 2");
    try testing.assertInstructionDisassembly("add cx, 8");
    try testing.assertInstructionDisassembly("add bx, [bp + 0]");
    try testing.assertInstructionDisassembly("add cx, [bx + 2]");
    try testing.assertInstructionDisassembly("add bh, [bp + si + 4]");
    try testing.assertInstructionDisassembly("add di, [bp + di + 6]");
    try testing.assertInstructionDisassembly("add [bx+si], bx");
    try testing.assertInstructionDisassembly("add [bp], bx");
    try testing.assertInstructionDisassembly("add [bp + 0], bx");
    try testing.assertInstructionDisassembly("add [bx + 2], cx");
    try testing.assertInstructionDisassembly("add [bp + si + 4], bh");
    try testing.assertInstructionDisassembly("add [bp + di + 6], di");
    try testing.assertInstructionDisassembly("add byte [bx], 34");
    try testing.assertInstructionDisassembly("add word [bp + si + 1000], 29");
    try testing.assertInstructionDisassembly("add ax, [bp]");
    try testing.assertInstructionDisassembly("add al, [bx + si]");
    try testing.assertInstructionDisassembly("add ax, bx");
    try testing.assertInstructionDisassembly("add al, ah");
    try testing.assertInstructionDisassembly("add ax, 1000");
    try testing.assertInstructionDisassembly("add al, -30");
    try testing.assertInstructionDisassembly("add al, 9");
}
