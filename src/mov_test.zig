const disassembler = @import("disassembler.zig");
const assertDisassembly = disassembler.assertDisassembly;
const assertDisassemblyToEqual = disassembler.assertDisassemblyToEqual;

test "disassemble mov register-to-register" {
    try assertDisassembly("mov ax, bx");
    try assertDisassembly("mov si, bx");
    try assertDisassembly("mov dh, al");
}

test "disassemble mov 8-bit immediate-to-register" {
    try assertDisassembly("mov cl, 12");
}

test "disassemble mov 16-bit immediate-to-register" {
    try assertDisassembly("mov cx, 12");
    try assertDisassembly("mov dx, 3948");
}

test "disassemble mov negative immediate" {
    try assertDisassemblyToEqual("mov cx, -12", "mov cx, 65524");
    try assertDisassemblyToEqual("mov dx, -3948", "mov dx, 61588");
    try assertDisassemblyToEqual("mov dl, -4", "mov dl, 252");
    try assertDisassemblyToEqual("mov dh, -4", "mov dh, 252");
}

test "disassemble mov source address calculation" {
    try assertDisassembly("mov dx, [si]");
    try assertDisassembly("mov dx, [di]");
    try assertDisassembly("mov dx, [bp]");
    try assertDisassembly("mov dx, [bx]");
    try assertDisassembly("mov bx, [bp + di]");
    try assertDisassembly("mov al, [bx + si]");
}

test "disassemble mov source address calculation plus 8-bit displacement" {
    try assertDisassembly("mov ah, [bx + si + 4]");
}

test "disassemble mov source address calculation plus 16-bit displacement" {
    try assertDisassembly("mov al, [bx + si + 4999]");
}

test "disassemble mov dest address calculation" {
    try assertDisassembly("mov [bx + di], cx");
    try assertDisassembly("mov [bp + si], cl");
    try assertDisassembly("mov [bp], ch");
    try assertDisassembly("mov [si + 1], cx");
}

test "disassemble mov signed displacements" {
    try assertDisassembly("mov ax, [bx + di - 37]");
    try assertDisassembly("mov [si - 300], cx");
    try assertDisassembly("mov dx, [bx - 32]");
}

test "disassemble mov explicit sizes" {
    try assertDisassembly("mov [bp + di], byte 7");
    try assertDisassembly("mov [di + 901], word 347");
    try assertDisassembly("mov [bx], byte 34");
    try assertDisassembly("mov [bp + si + 1000], word 29");
    try assertDisassembly("mov [4834], byte 29");
    try assertDisassembly("mov [4834], word 29");
}

test "disassemble mov direct address" {
    try assertDisassembly("mov bp, [5]");
    try assertDisassembly("mov bx, [3458]");
}

test "disassemble mov memory-to-accumulator test" {
    try assertDisassembly("mov ax, [2555]");
    try assertDisassembly("mov ax, [16]");
    try assertDisassembly("mov al, [16]");
}

test "disassemble mov accumulator-to-memory test" {
    try assertDisassembly("mov [2554], ax");
    try assertDisassembly("mov [15], ax");
    try assertDisassembly("mov [15], al");
}

test "disassemble mov segment registers" {
    try assertDisassembly("mov es, ax");
    try assertDisassembly("mov cs, bx");
    try assertDisassembly("mov ss, cx");
    try assertDisassembly("mov ds, dx");

    try assertDisassembly("mov ax, es");
    try assertDisassembly("mov bx, cs");
    try assertDisassembly("mov cx, ss");
    try assertDisassembly("mov dx, ds");
}

test "disassemble mov multi-line" {
    try assertDisassembly(
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

test "disassemble add" {
    try assertDisassembly("add bx, [bx + si]");
    try assertDisassembly("add bx, [bp]");
    try assertDisassembly("add si, 2");
    try assertDisassembly("add bp, 2");
    try assertDisassembly("add cx, 8");
    try assertDisassembly("add bx, [bp]");
    try assertDisassembly("add cx, [bx + 2]");
    try assertDisassembly("add bh, [bp + si + 4]");
    try assertDisassembly("add di, [bp + di + 6]");
    try assertDisassembly("add [bx + si], bx");
    try assertDisassembly("add [bp], bx");
    try assertDisassembly("add [bx + 2], cx");
    try assertDisassembly("add [bp + si + 4], bh");
    try assertDisassembly("add [bp + di + 6], di");
    try assertDisassembly("add [bx], byte 34");
    try assertDisassembly("add [bp + si + 1000], word 29");
    try assertDisassembly("add ax, [bp]");
    try assertDisassembly("add al, [bx + si]");
    try assertDisassembly("add ax, bx");
    try assertDisassembly("add al, ah");
    try assertDisassembly("add ax, 1000");
    try assertDisassembly("add al, 9");
    try assertDisassembly("add bp, 258");
}

test "disassemble sub" {
    try assertDisassembly("sub bx, [bx + si]");
    try assertDisassembly("sub bx, [bp]");
    try assertDisassembly("sub si, 2");
    try assertDisassembly("sub bp, 2");
    try assertDisassembly("sub cx, 8");
    try assertDisassembly("sub cx, [bx + 2]");
    try assertDisassembly("sub bh, [bp + si + 4]");
    try assertDisassembly("sub di, [bp + di + 6]");
    try assertDisassembly("sub [bx + si], bx");
    try assertDisassembly("sub [bp], bx");
    try assertDisassembly("sub [bx + 2], cx");
    try assertDisassembly("sub [bp + si + 4], bh");
    try assertDisassembly("sub [bp + di + 6], di");
    try assertDisassembly("sub [bx], byte 34");
    try assertDisassembly("sub [bx + di], word 29");
    try assertDisassembly("sub ax, [bp]");
    try assertDisassembly("sub al, [bx + si]");
    try assertDisassembly("sub ax, bx");
    try assertDisassembly("sub al, ah");
    try assertDisassembly("sub ax, 1000");
    try assertDisassembly("sub al, 9");

    try assertDisassemblyToEqual("sub cx, -12", "sub cx, 65524");
    try assertDisassemblyToEqual("sub dx, -3948", "sub dx, 61588");
    try assertDisassemblyToEqual("sub dl, -4", "sub dl, 252");
    try assertDisassemblyToEqual("sub dh, -4", "sub dh, 252");
}

test "disassemble cmp" {
    try assertDisassembly("cmp bx, [bx + si]");
    try assertDisassembly("cmp bx, [bp]");
    try assertDisassembly("cmp si, 2");
    try assertDisassembly("cmp bp, 2");
    try assertDisassembly("cmp cx, 8");
    try assertDisassembly("cmp bx, [bp]");
    try assertDisassembly("cmp cx, [bx + 2]");
    try assertDisassembly("cmp bh, [bp + si + 4]");
    try assertDisassembly("cmp di, [bp + di + 6]");
    try assertDisassembly("cmp [bx + si], bx");
    try assertDisassembly("cmp [bp], bx");
    try assertDisassembly("cmp [bx + 2], cx");
    try assertDisassembly("cmp [bp + si + 4], bh");
    try assertDisassembly("cmp [bp + di + 6], di");
    try assertDisassembly("cmp [bx], byte 34");
    try assertDisassembly("cmp [4834], word 29");
    try assertDisassembly("cmp ax, [bp]");
    try assertDisassembly("cmp al, [bx + si]");
    try assertDisassembly("cmp ax, bx");
    try assertDisassembly("cmp al, ah");
    try assertDisassembly("cmp ax, 1000");
    try assertDisassembly("cmp al, 9");
}

const simulator = @import("simulator.zig");
const SimulatorState = simulator.SimulatorState;
const assertSimulationToEqual = simulator.assertSimulationToEqual;
const assertSimulationToEqualWithState = simulator.assertSimulationToEqualWithState;

test "simulate mov" {
    try assertSimulationToEqual(
        \\mov ax, 1
        \\mov bx, 2
        \\mov cx, 3
        \\mov dx, 4
        \\mov sp, 5
        \\mov bp, 6
        \\mov si, 7
        \\mov di, 8
    , .{ .at = 8, .registers = .{ .main = [_]u8{ 1, 0, 3, 0, 4, 0, 2, 0 }, .rest = [_]u16{ 5, 6, 7, 8 } ++ [_]u16{0} ** 5 } });

    try assertSimulationToEqual(
        \\mov ax, 1
        \\mov bx, 2
        \\mov cx, 3
        \\mov dx, 4
        \\
        \\mov sp, ax
        \\mov bp, bx
        \\mov si, cx
        \\mov di, dx
        \\
        \\mov dx, sp
        \\mov cx, bp
        \\mov bx, si
        \\mov ax, di
    , .{ .at = 12, .registers = .{ .main = [_]u8{ 4, 0, 2, 0, 1, 0, 3, 0 }, .rest = [_]u16{ 1, 2, 3, 4 } ++ [_]u16{0} ** 5 } });

    try assertSimulationToEqual(
        \\mov ax, 0x2222
        \\mov bx, 0x4444
        \\mov cx, 0x6666
        \\mov dx, 0x8888
        \\
        \\mov ss, ax
        \\mov ds, bx
        \\mov es, cx
        \\
        \\mov al, 0x11
        \\mov bh, 0x33
        \\mov cl, 0x55
        \\mov dh, 0x77
        \\
        \\mov ah, bl
        \\mov cl, dh
        \\
        \\mov ss, ax
        \\mov ds, bx
        \\mov es, cx
        \\
        \\mov sp, ss
        \\mov bp, ds
        \\mov si, es
        \\mov di, dx
    , .{ .at = 20, .registers = .{
        .main = [_]u8{ 0x11, 0x44, 0x77, 0x66, 0x88, 0x77, 0x44, 0x33 },
        .rest = [_]u16{ 17425, 13124, 26231, 30600, 0, 26231, 0, 17425, 13124 },
    } });
}

test "simulate sub" {
    try assertSimulationToEqual(
        \\mov ax, 50
        \\sub ax, 50
    , .{ .at = 2, .flags = .{ .zero = true, .parity = true } });

    try assertSimulationToEqual(
        \\mov ax, 51
        \\sub ax, 50
    , .{ .at = 2, .registers = .{ .main = [_]u8{1} ++ [_]u8{0} ** 7 }, .flags = .{} });

    try assertSimulationToEqual(
        \\mov al, 0
        \\sub al, 1
    , .{ .at = 2, .registers = .{ .main = [_]u8{255} ++ [_]u8{0} ** 7 }, .flags = .{ .sign = true, .parity = true, .carry = true, .auxiliary = true } });

    try assertSimulationToEqual(
        \\mov bx, -4093
        \\mov cx, 3841
        \\sub bx, cx
        \\
        \\mov sp, 998
        \\mov bp, 999
        \\cmp bp, sp
        \\
        \\add bp, 1027
        \\sub bp, 2026
    , .{
        .at = 8,
        .registers = .{ .main = [_]u8{ 0, 0, 0x01, 0x0f, 0, 0, 0x02, 0xe1 }, .rest = [_]u16{998} ++ [_]u16{0} ** 8 },
        .flags = .{ .zero = true, .parity = true },
    });

    var state = SimulatorState{};
    try assertSimulationToEqualWithState("add bx, 30000", &state, .{ .at = 1, .registers = .{ .main = [_]u8{ 0, 0, 0, 0, 0, 0, 0x30, 0x75 } }, .flags = .{ .parity = true } });
    try assertSimulationToEqualWithState("add bx, 10000", &state, .{ .at = 1, .registers = .{ .main = [_]u8{ 0, 0, 0, 0, 0, 0, 0x40, 0x9c } }, .flags = .{ .sign = true, .overflow = true } });
    try assertSimulationToEqualWithState("sub bx, 5000", &state, .{ .at = 1, .registers = .{ .main = [_]u8{ 0, 0, 0, 0, 0, 0, 0xb8, 0x88 } }, .flags = .{ .parity = true, .sign = true, .auxiliary = true } });
    try assertSimulationToEqualWithState("sub bx, 5000", &state, .{ .at = 1, .registers = .{ .main = [_]u8{ 0, 0, 0, 0, 0, 0, 0x30, 0x75 } }, .flags = .{ .parity = true, .overflow = true } });

    try assertSimulationToEqualWithState("mov bx, 1", &state, .{ .at = 1, .registers = .{ .main = [_]u8{ 0, 0, 0, 0, 0, 0, 0x01, 0x00 } }, .flags = .{ .parity = true, .overflow = true } });
    try assertSimulationToEqualWithState("mov cx, 100", &state, .{ .at = 1, .registers = .{ .main = [_]u8{ 0, 0, 0x64, 0, 0, 0, 0x01, 0x00 } }, .flags = .{ .parity = true, .overflow = true } });
    try assertSimulationToEqualWithState("add bx, cx", &state, .{ .at = 1, .registers = .{ .main = [_]u8{ 0, 0, 0x64, 0, 0, 0, 0x65, 0x00 } }, .flags = .{ .parity = true } });

    try assertSimulationToEqualWithState("mov dx, 10", &state, .{ .at = 1, .registers = .{ .main = [_]u8{ 0, 0, 0x64, 0, 0x0a, 0, 0x65, 0x00 } }, .flags = .{ .parity = true } });
    try assertSimulationToEqualWithState("sub cx, dx", &state, .{ .at = 1, .registers = .{ .main = [_]u8{ 0, 0, 0x5a, 0, 0x0a, 0, 0x65, 0x00 } }, .flags = .{ .parity = true, .auxiliary = true } });

    try assertSimulationToEqualWithState("add bx, 40000", &state, .{ .at = 1, .registers = .{ .main = [_]u8{ 0, 0, 0x5a, 0, 0x0a, 0, 0xa5, 0x9c } }, .flags = .{ .parity = true, .sign = true } });
    try assertSimulationToEqualWithState("add cx, -90", &state, .{ .at = 1, .registers = .{ .main = [_]u8{ 0, 0, 0x00, 0, 0x0a, 0, 0xa5, 0x9c } }, .flags = .{ .parity = true, .auxiliary = true, .carry = true, .zero = true } });

    try assertSimulationToEqualWithState("mov sp, 99", &state, .{ .at = 1, .registers = .{ .main = [_]u8{ 0, 0, 0x00, 0, 0x0a, 0, 0xa5, 0x9c }, .rest = [_]u16{0x63} ++ [_]u16{0} ** 8 }, .flags = .{ .parity = true, .auxiliary = true, .carry = true, .zero = true } });
    try assertSimulationToEqualWithState("mov bp, 98", &state, .{ .at = 1, .registers = .{ .main = [_]u8{ 0, 0, 0x00, 0, 0x0a, 0, 0xa5, 0x9c }, .rest = [_]u16{ 0x63, 0x62 } ++ [_]u16{0} ** 7 }, .flags = .{ .parity = true, .auxiliary = true, .carry = true, .zero = true } });
    try assertSimulationToEqualWithState("cmp bp, sp", &state, .{ .at = 1, .registers = .{ .main = [_]u8{ 0, 0, 0x00, 0, 0x0a, 0, 0xa5, 0x9c }, .rest = [_]u16{ 0x63, 0x62 } ++ [_]u16{0} ** 7 }, .flags = .{ .parity = true, .auxiliary = true, .carry = true, .sign = true } });
}
