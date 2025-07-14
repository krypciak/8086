const testing = @import("test.zig");

test "add" {
    try testing.assertDisassembly("add bx, [bx + si]");
    try testing.assertDisassembly("add bx, [bp]");
    try testing.assertDisassembly("add si, 2");
    try testing.assertDisassembly("add bp, 2");
    try testing.assertDisassembly("add cx, 8");
    try testing.assertDisassembly("add bx, [bp]");
    try testing.assertDisassembly("add cx, [bx + 2]");
    try testing.assertDisassembly("add bh, [bp + si + 4]");
    try testing.assertDisassembly("add di, [bp + di + 6]");
    try testing.assertDisassembly("add [bx + si], bx");
    try testing.assertDisassembly("add [bp], bx");
    try testing.assertDisassembly("add [bx + 2], cx");
    try testing.assertDisassembly("add [bp + si + 4], bh");
    try testing.assertDisassembly("add [bp + di + 6], di");
    try testing.assertDisassembly("add [bx], byte 34");
    try testing.assertDisassembly("add [bp + si + 1000], word 29");
    try testing.assertDisassembly("add ax, [bp]");
    try testing.assertDisassembly("add al, [bx + si]");
    try testing.assertDisassembly("add ax, bx");
    try testing.assertDisassembly("add al, ah");
    try testing.assertDisassembly("add ax, 1000");
    try testing.assertDisassembly("add al, 9");
}
