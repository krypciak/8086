const testing = @import("test.zig");

test "mov register-to-register" {
    try testing.assertInstructionDisassembly("mov ax, bx");
    try testing.assertInstructionDisassembly("mov si, bx");
    try testing.assertInstructionDisassembly("mov dh, al");
}

test "mov 8-bit immediate-to-register" {
    try testing.assertInstructionDisassembly("mov cl, 12");
}

test "mov 16-bit immediate-to-register" {
    try testing.assertInstructionDisassembly("mov cx, 12");
    try testing.assertInstructionDisassembly("mov dx, 3948");
}

test "mov source address calculation" {
    try testing.assertInstructionDisassembly("mov dx, [si]");
    try testing.assertInstructionDisassembly("mov dx, [di]");
    try testing.assertInstructionDisassembly("mov dx, [bp]");
    try testing.assertInstructionDisassembly("mov dx, [bx]");
    try testing.assertInstructionDisassembly("mov bx, [bp + di]");
    try testing.assertInstructionDisassembly("mov al, [bx + si]");
}

test "mov source address calculation plus 8-bit displacement" {
    try testing.assertInstructionDisassembly("mov ah, [bx + si + 4]");
}

test "mov source address calculation plus 16-bit displacement" {
    try testing.assertInstructionDisassembly("mov al, [bx + si + 4999]");
}

test "mov dest address calculation" {
    try testing.assertInstructionDisassembly("mov [bx + di], cx");
    try testing.assertInstructionDisassembly("mov [bp + si], cl");
    try testing.assertInstructionDisassembly("mov [bp], ch");
    try testing.assertInstructionDisassembly("mov [si + 1], cx");
}

test "mov signed displacements" {
    try testing.assertInstructionDisassembly("mov ax, [bx + di - 37]");
    try testing.assertInstructionDisassembly("mov [si - 300], cx");
    try testing.assertInstructionDisassembly("mov dx, [bx - 32]");
}

test "mov explicit sizes" {
    try testing.assertInstructionDisassembly("mov [bp + di], byte 7");
    try testing.assertInstructionDisassembly("mov [di + 901], word 347");
}

test "mov direct address" {
    try testing.assertInstructionDisassembly("mov bp, [5]");
    try testing.assertInstructionDisassembly("mov bx, [3458]");
}

test "mov memory-to-accumulator test" {
    try testing.assertInstructionDisassembly("mov ax, [2555]");
    try testing.assertInstructionDisassembly("mov ax, [16]");
    try testing.assertInstructionDisassembly("mov al, [16]");
}

test "mov accumulator-to-memory test" {
    try testing.assertInstructionDisassembly("mov [2554], ax");
    try testing.assertInstructionDisassembly("mov [15], ax");
    try testing.assertInstructionDisassembly("mov [15], al");
}
