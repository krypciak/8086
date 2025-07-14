const testing = @import("test.zig");

test "sub" {
    try testing.assertDisassembly("sub bx, [bx + si]");
    try testing.assertDisassembly("sub bx, [bp]");
    try testing.assertDisassembly("sub si, 2");
    try testing.assertDisassembly("sub bp, 2");
    try testing.assertDisassembly("sub cx, 8");
    try testing.assertDisassembly("sub cx, [bx + 2]");
    try testing.assertDisassembly("sub bh, [bp + si + 4]");
    try testing.assertDisassembly("sub di, [bp + di + 6]");
    try testing.assertDisassembly("sub [bx + si], bx");
    try testing.assertDisassembly("sub [bp], bx");
    try testing.assertDisassembly("sub [bx + 2], cx");
    try testing.assertDisassembly("sub [bp + si + 4], bh");
    try testing.assertDisassembly("sub [bp + di + 6], di");
    try testing.assertDisassembly("sub [bx], byte 34");
    try testing.assertDisassembly("sub [bx + di], word 29");
    try testing.assertDisassembly("sub ax, [bp]");
    try testing.assertDisassembly("sub al, [bx + si]");
    try testing.assertDisassembly("sub ax, bx");
    try testing.assertDisassembly("sub al, ah");
    try testing.assertDisassembly("sub ax, 1000");
    try testing.assertDisassembly("sub al, 9");
}
