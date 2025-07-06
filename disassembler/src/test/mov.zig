const testing = @import("test.zig");

test "mov register-to-register" {
    try testing.assertInstructionDisassembly("mov ax, bx");
    try testing.assertInstructionDisassembly("mov si, bx");
    try testing.assertInstructionDisassembly("mov dh, al");
}

test "mov 8-bit immediate-to-register" {
    try testing.assertInstructionDisassembly("mov cl, 12");
    // try testing.assertInstructionDisassembly("mov ch, -12");
}

// test "mov 16-bit immediate-to-register" {
//     try testing.assertInstructionDisassembly("mov cx, 12");
//     try testing.assertInstructionDisassembly("mov cx, -12");
//     try testing.assertInstructionDisassembly("mov dx, 3948");
//     try testing.assertInstructionDisassembly("mov dx, -3948");
// }
//
// test "mov source address calculation" {
//     try testing.assertInstructionDisassembly("mov al, [bx + si]");
//     try testing.assertInstructionDisassembly("mov bx, [bp + di]");
//     try testing.assertInstructionDisassembly("mov dx, [bp]");
// }
//
// test "mov source address calculation plus 8-bit displacement" {
//     try testing.assertInstructionDisassembly("mov ah, [bx + si + 4]");
// }
//
// test "mov source address calculation plus 16-bit displacement" {
//     try testing.assertInstructionDisassembly("mov al, [bx + si + 4999]");
// }
//
// test "mov dest address calculation" {
//     try testing.assertInstructionDisassembly("mov [bx + di], cx");
//     try testing.assertInstructionDisassembly("mov [bp + si], cl");
//     try testing.assertInstructionDisassembly("mov [bp], ch");
// }
