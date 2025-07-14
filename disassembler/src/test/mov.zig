const testing = @import("test.zig");

test "mov register-to-register" {
    try testing.assertDisassembly("mov ax, bx");
    try testing.assertDisassembly("mov si, bx");
    try testing.assertDisassembly("mov dh, al");
}

test "mov 8-bit immediate-to-register" {
    try testing.assertDisassembly("mov cl, 12");
}

test "mov 16-bit immediate-to-register" {
    try testing.assertDisassembly("mov cx, 12");
    try testing.assertDisassembly("mov dx, 3948");
}

test "mov source address calculation" {
    try testing.assertDisassembly("mov dx, [si]");
    try testing.assertDisassembly("mov dx, [di]");
    try testing.assertDisassembly("mov dx, [bp]");
    try testing.assertDisassembly("mov dx, [bx]");
    try testing.assertDisassembly("mov bx, [bp + di]");
    try testing.assertDisassembly("mov al, [bx + si]");
}

test "mov source address calculation plus 8-bit displacement" {
    try testing.assertDisassembly("mov ah, [bx + si + 4]");
}

test "mov source address calculation plus 16-bit displacement" {
    try testing.assertDisassembly("mov al, [bx + si + 4999]");
}

test "mov dest address calculation" {
    try testing.assertDisassembly("mov [bx + di], cx");
    try testing.assertDisassembly("mov [bp + si], cl");
    try testing.assertDisassembly("mov [bp], ch");
    try testing.assertDisassembly("mov [si + 1], cx");
}

test "mov signed displacements" {
    try testing.assertDisassembly("mov ax, [bx + di - 37]");
    try testing.assertDisassembly("mov [si - 300], cx");
    try testing.assertDisassembly("mov dx, [bx - 32]");
}

test "mov explicit sizes" {
    try testing.assertDisassembly("mov [bp + di], byte 7");
    try testing.assertDisassembly("mov [di + 901], word 347");
    try testing.assertDisassembly("mov [bx], byte 34");
    try testing.assertDisassembly("mov [bp + si + 1000], word 29");
    try testing.assertDisassembly("mov [4834], byte 29");
    try testing.assertDisassembly("mov [4834], word 29");
}

test "mov direct address" {
    try testing.assertDisassembly("mov bp, [5]");
    try testing.assertDisassembly("mov bx, [3458]");
}

test "mov memory-to-accumulator test" {
    try testing.assertDisassembly("mov ax, [2555]");
    try testing.assertDisassembly("mov ax, [16]");
    try testing.assertDisassembly("mov al, [16]");
}

test "mov accumulator-to-memory test" {
    try testing.assertDisassembly("mov [2554], ax");
    try testing.assertDisassembly("mov [15], ax");
    try testing.assertDisassembly("mov [15], al");
}

test "mov multi-line" {
    try testing.assertDisassembly(
        \\mov ax, bx
        \\mov si, bx
        \\mov dh, al
        \\mov cl, 12
        \\mov cx, 12
        \\mov dx, 3948
        \\mov dx, [si]
        \\mov dx, [di]
        \\mov dx, [bp]
        \\mov dx, [bx]
        \\mov bx, [bp + di]
        \\mov al, [bx + si]
        \\mov ah, [bx + si + 4]
        \\mov al, [bx + si + 4999]
        \\mov [bx + di], cx
        \\mov [bp + si], cl
        \\mov [bp], ch
        \\mov [si + 1], cx
        \\mov ax, [bx + di - 37]
        \\mov [si - 300], cx
        \\mov dx, [bx - 32]
        \\mov [bp + di], byte 7
        \\mov [di + 901], word 347
        \\mov [bx], byte 34
        \\mov [bp + si + 1000], word 29
        \\mov [4834], byte 29
        \\mov [4834], word 29
        \\mov bp, [5]
        \\mov bx, [3458]
        \\mov ax, [2555]
        \\mov ax, [16]
        \\mov al, [16]
        \\mov [2554], ax
        \\mov [15], ax
        \\mov [15], al
    );
}
