const testing = @import("test.zig");

test "cmp" {
    try testing.assertDisassembly("cmp bx, [bx + si]");
    try testing.assertDisassembly("cmp bx, [bp]");
    try testing.assertDisassembly("cmp si, 2");
    try testing.assertDisassembly("cmp bp, 2");
    try testing.assertDisassembly("cmp cx, 8");
    try testing.assertDisassembly("cmp bx, [bp]");
    try testing.assertDisassembly("cmp cx, [bx + 2]");
    try testing.assertDisassembly("cmp bh, [bp + si + 4]");
    try testing.assertDisassembly("cmp di, [bp + di + 6]");
    try testing.assertDisassembly("cmp [bx + si], bx");
    try testing.assertDisassembly("cmp [bp], bx");
    try testing.assertDisassembly("cmp [bx + 2], cx");
    try testing.assertDisassembly("cmp [bp + si + 4], bh");
    try testing.assertDisassembly("cmp [bp + di + 6], di");
    try testing.assertDisassembly("cmp [bx], byte 34");
    try testing.assertDisassembly("cmp [4834], word 29");
    try testing.assertDisassembly("cmp ax, [bp]");
    try testing.assertDisassembly("cmp al, [bx + si]");
    try testing.assertDisassembly("cmp ax, bx");
    try testing.assertDisassembly("cmp al, ah");
    try testing.assertDisassembly("cmp ax, 1000");
    try testing.assertDisassembly("cmp al, 9");
}
