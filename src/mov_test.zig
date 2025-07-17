const disassembler = @import("disassembler.zig");
const assertDisassembly = disassembler.assertDisassembly;
const assertDisassemblyToEqual = disassembler.assertDisassemblyToEqual;

test "disassemble mov register-to-register 1" {
    try assertDisassembly("mov ax, bx");
}
test "disassemble mov register-to-register 2" {
    try assertDisassembly("mov si, bx");
}
test "disassemble mov register-to-register 3" {
    try assertDisassembly("mov dh, al");
}

test "disassemble mov 8-bit immediate-to-register 1" {
    try assertDisassembly("mov cl, 12");
}

test "disassemble mov 16-bit immediate-to-register 1" {
    try assertDisassembly("mov cx, 12");
}
test "disassemble mov 16-bit immediate-to-register 2" {
    try assertDisassembly("mov dx, 3948");
}

test "disassemble mov negative immediate 1" {
    try assertDisassemblyToEqual("mov cx, -12", "mov cx, 65524");
}
test "disassemble mov negative immediate 2" {
    try assertDisassemblyToEqual("mov dx, -3948", "mov dx, 61588");
}
test "disassemble mov negative immediate 3" {
    try assertDisassemblyToEqual("mov dl, -4", "mov dl, 252");
}
test "disassemble mov negative immediate 4" {
    try assertDisassemblyToEqual("mov dh, -4", "mov dh, 252");
}

test "disassemble mov source address calculation 1" {
    try assertDisassembly("mov dx, [si]");
}
test "disassemble mov source address calculation 2" {
    try assertDisassembly("mov dx, [di]");
}
test "disassemble mov source address calculation 3" {
    try assertDisassembly("mov dx, [bp]");
}
test "disassemble mov source address calculation 4" {
    try assertDisassembly("mov dx, [bx]");
}
test "disassemble mov source address calculation 5" {
    try assertDisassembly("mov bx, [bp + di]");
}
test "disassemble mov source address calculation 6" {
    try assertDisassembly("mov al, [bx + si]");
}

test "disassemble mov source address calculation plus 8-bit displacement 1" {
    try assertDisassembly("mov ah, [bx + si + 4]");
}

test "disassemble mov source address calculation plus 16-bit displacement 1" {
    try assertDisassembly("mov al, [bx + si + 4999]");
}

test "disassemble mov dest address calculation 1" {
    try assertDisassembly("mov [bx + di], cx");
}
test "disassemble mov dest address calculation 2" {
    try assertDisassembly("mov [bp + si], cl");
}
test "disassemble mov dest address calculation 3" {
    try assertDisassembly("mov [bp], ch");
}
test "disassemble mov dest address calculation 4" {
    try assertDisassembly("mov [si + 1], cx");
}

test "disassemble mov signed displacements 1" {
    try assertDisassembly("mov ax, [bx + di - 37]");
}
test "disassemble mov signed displacements 2" {
    try assertDisassembly("mov [si - 300], cx");
}
test "disassemble mov signed displacements 3" {
    try assertDisassembly("mov dx, [bx - 32]");
}

test "disassemble mov explicit sizes 1" {
    try assertDisassembly("mov [bp + di], byte 7");
}
test "disassemble mov explicit sizes 2" {
    try assertDisassembly("mov [di + 901], word 347");
}
test "disassemble mov explicit sizes 3" {
    try assertDisassembly("mov [bx], byte 34");
}
test "disassemble mov explicit sizes 4" {
    try assertDisassembly("mov [bp + si + 1000], word 29");
}
test "disassemble mov explicit sizes 5" {
    try assertDisassembly("mov [4834], byte 29");
}
test "disassemble mov explicit sizes 6" {
    try assertDisassembly("mov [4834], word 29");
}
test "disassemble mov explicit sizes 7" {
    try assertDisassembly("mov [bx + 4], word 10");
}

test "disassemble mov direct address 1" {
    try assertDisassembly("mov bp, [5]");
}
test "disassemble mov direct address 2" {
    try assertDisassembly("mov bx, [3458]");
}

test "disassemble mov memory-to-accumulator test 1" {
    try assertDisassembly("mov ax, [2555]");
}
test "disassemble mov memory-to-accumulator test 2" {
    try assertDisassembly("mov ax, [16]");
}
test "disassemble mov memory-to-accumulator test 3" {
    try assertDisassembly("mov al, [16]");
}

test "disassemble mov accumulator-to-memory test 1" {
    try assertDisassembly("mov [2554], ax");
}
test "disassemble mov accumulator-to-memory test 2" {
    try assertDisassembly("mov [15], ax");
}
test "disassemble mov accumulator-to-memory test 3" {
    try assertDisassembly("mov [15], al");
}

test "disassemble mov segment registers 1" {
    try assertDisassembly("mov es, ax");
}
test "disassemble mov segment registers 2" {
    try assertDisassembly("mov cs, bx");
}
test "disassemble mov segment registers 3" {
    try assertDisassembly("mov ss, cx");
}
test "disassemble mov segment registers 4" {
    try assertDisassembly("mov ds, dx");
}
test "disassemble mov segment registers 5" {
    try assertDisassembly("mov ax, es");
}
test "disassemble mov segment registers 6" {
    try assertDisassembly("mov bx, cs");
}
test "disassemble mov segment registers 7" {
    try assertDisassembly("mov cx, ss");
}
test "disassemble mov segment registers 8" {
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

test "disassemble add 1" {
    try assertDisassembly("add bx, [bx + si]");
}
test "disassemble add 2" {
    try assertDisassembly("add bx, [bp]");
}
test "disassemble add 3" {
    try assertDisassembly("add si, 2");
}
test "disassemble add 4" {
    try assertDisassembly("add bp, 2");
}
test "disassemble add 5" {
    try assertDisassembly("add cx, 8");
}
test "disassemble add 6" {
    try assertDisassembly("add bx, [bp]");
}
test "disassemble add 7" {
    try assertDisassembly("add cx, [bx + 2]");
}
test "disassemble add 8" {
    try assertDisassembly("add bh, [bp + si + 4]");
}
test "disassemble add 9" {
    try assertDisassembly("add di, [bp + di + 6]");
}
test "disassemble add 10" {
    try assertDisassembly("add [bx + si], bx");
}
test "disassemble add 11" {
    try assertDisassembly("add [bp], bx");
}
test "disassemble add 12" {
    try assertDisassembly("add [bx + 2], cx");
}
test "disassemble add 13" {
    try assertDisassembly("add [bp + si + 4], bh");
}
test "disassemble add 14" {
    try assertDisassembly("add [bp + di + 6], di");
}
test "disassemble add 15" {
    try assertDisassembly("add [bx], byte 34");
}
test "disassemble add 16" {
    try assertDisassembly("add [bp + si + 1000], word 29");
}
test "disassemble add 17" {
    try assertDisassembly("add ax, [bp]");
}
test "disassemble add 18" {
    try assertDisassembly("add al, [bx + si]");
}
test "disassemble add 19" {
    try assertDisassembly("add ax, bx");
}
test "disassemble add 20" {
    try assertDisassembly("add al, ah");
}
test "disassemble add 21" {
    try assertDisassembly("add ax, 1000");
}
test "disassemble add 22" {
    try assertDisassembly("add al, 9");
}
test "disassemble add 23" {
    try assertDisassembly("add bp, 258");
}

test "disassemble sub 1" {
    try assertDisassembly("sub bx, [bx + si]");
}
test "disassemble sub 2" {
    try assertDisassembly("sub bx, [bp]");
}
test "disassemble sub 3" {
    try assertDisassembly("sub si, 2");
}
test "disassemble sub 4" {
    try assertDisassembly("sub bp, 2");
}
test "disassemble sub 5" {
    try assertDisassembly("sub cx, 8");
}
test "disassemble sub 6" {
    try assertDisassembly("sub cx, [bx + 2]");
}
test "disassemble sub 7" {
    try assertDisassembly("sub bh, [bp + si + 4]");
}
test "disassemble sub 8" {
    try assertDisassembly("sub di, [bp + di + 6]");
}
test "disassemble sub 9" {
    try assertDisassembly("sub [bx + si], bx");
}
test "disassemble sub 10" {
    try assertDisassembly("sub [bp], bx");
}
test "disassemble sub 11" {
    try assertDisassembly("sub [bx + 2], cx");
}
test "disassemble sub 12" {
    try assertDisassembly("sub [bp + si + 4], bh");
}
test "disassemble sub 13" {
    try assertDisassembly("sub [bp + di + 6], di");
}
test "disassemble sub 14" {
    try assertDisassembly("sub [bx], byte 34");
}
test "disassemble sub 15" {
    try assertDisassembly("sub [bx + di], word 29");
}
test "disassemble sub 16" {
    try assertDisassembly("sub ax, [bp]");
}
test "disassemble sub 17" {
    try assertDisassembly("sub al, [bx + si]");
}
test "disassemble sub 18" {
    try assertDisassembly("sub ax, bx");
}
test "disassemble sub 19" {
    try assertDisassembly("sub al, ah");
}
test "disassemble sub 20" {
    try assertDisassembly("sub ax, 1000");
}
test "disassemble sub 21" {
    try assertDisassembly("sub al, 9");
}
test "disassemble sub 22" {
    try assertDisassemblyToEqual("sub cx, -12", "sub cx, 65524");
}
test "disassemble sub 23" {
    try assertDisassemblyToEqual("sub dx, -3948", "sub dx, 61588");
}
test "disassemble sub 24" {
    try assertDisassemblyToEqual("sub dl, -4", "sub dl, 252");
}
test "disassemble sub 25" {
    try assertDisassemblyToEqual("sub dh, -4", "sub dh, 252");
}

test "disassemble cmp 1" {
    try assertDisassembly("cmp bx, [bx + si]");
}
test "disassemble cmp 2" {
    try assertDisassembly("cmp bx, [bp]");
}
test "disassemble cmp 3" {
    try assertDisassembly("cmp si, 2");
}
test "disassemble cmp 4" {
    try assertDisassembly("cmp bp, 2");
}
test "disassemble cmp 5" {
    try assertDisassembly("cmp cx, 8");
}
test "disassemble cmp 6" {
    try assertDisassembly("cmp bx, [bp]");
}
test "disassemble cmp 7" {
    try assertDisassembly("cmp cx, [bx + 2]");
}
test "disassemble cmp 8" {
    try assertDisassembly("cmp bh, [bp + si + 4]");
}
test "disassemble cmp 9" {
    try assertDisassembly("cmp di, [bp + di + 6]");
}
test "disassemble cmp 10" {
    try assertDisassembly("cmp [bx + si], bx");
}
test "disassemble cmp 11" {
    try assertDisassembly("cmp [bp], bx");
}
test "disassemble cmp 12" {
    try assertDisassembly("cmp [bx + 2], cx");
}
test "disassemble cmp 13" {
    try assertDisassembly("cmp [bp + si + 4], bh");
}
test "disassemble cmp 14" {
    try assertDisassembly("cmp [bp + di + 6], di");
}
test "disassemble cmp 15" {
    try assertDisassembly("cmp [bx], byte 34");
}
test "disassemble cmp 16" {
    try assertDisassembly("cmp [4834], word 29");
}
test "disassemble cmp 17" {
    try assertDisassembly("cmp ax, [bp]");
}
test "disassemble cmp 18" {
    try assertDisassembly("cmp al, [bx + si]");
}
test "disassemble cmp 19" {
    try assertDisassembly("cmp ax, bx");
}
test "disassemble cmp 20" {
    try assertDisassembly("cmp al, ah");
}
test "disassemble cmp 21" {
    try assertDisassembly("cmp ax, 1000");
}
test "disassemble cmp 22" {
    try assertDisassembly("cmp al, 9");
}

const simulator = @import("simulator.zig");
const SimulatorState = simulator.SimulatorState;
const assertSimulationToEqual = simulator.assertSimulationToEqual;
const assertSimulationToEqualWithState = simulator.assertSimulationToEqualWithState;

test "simulate mov 1" {
    try assertSimulationToEqual(
        \\mov ax, 1
        \\mov bx, 2
        \\mov cx, 3
        \\mov dx, 4
        \\mov sp, 5
        \\mov bp, 6
        \\mov si, 7
        \\mov di, 8
    , .{ .registers = .{ .ip = 24, .main = .{ 1, 0, 3, 0, 4, 0, 2, 0 }, .rest = .{ 5, 6, 7, 8 } ++ .{0} ** 4 } });
}
test "simuate mov 2" {
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
    , .{ .registers = .{ .ip = 28, .main = .{ 4, 0, 2, 0, 1, 0, 3, 0 }, .rest = .{ 1, 2, 3, 4 } ++ .{0} ** 4 } });
}
test "simulate mov 3" {
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
    , .{ .registers = .{
        .ip = 44,
        .main = .{ 0x11, 0x44, 0x77, 0x66, 0x88, 0x77, 0x44, 0x33 },
        .rest = .{ 17425, 13124, 26231, 30600, 26231, 0, 17425, 13124 },
    } });
}

test "simulate sub 1" {
    try assertSimulationToEqual(
        \\mov ax, 50
        \\sub ax, 50
    , .{ .registers = .{ .ip = 6 }, .flags = .{ .zero = true, .parity = true } });
}
test "simulate sub 2" {
    try assertSimulationToEqual(
        \\mov ax, 51
        \\sub ax, 50
    , .{ .registers = .{ .ip = 6, .main = .{1} ++ .{0} ** 7 }, .flags = .{} });
}
test "simulate sub 3" {
    try assertSimulationToEqual(
        \\mov al, 0
        \\sub al, 1
    , .{ .registers = .{ .ip = 4, .main = .{255} ++ .{0} ** 7 }, .flags = .{ .sign = true, .parity = true, .carry = true, .auxiliary = true } });
}

test "simulate mov sub cmp" {
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
        .registers = .{ .ip = 24, .main = .{ 0, 0, 0x01, 0x0f, 0, 0, 0x02, 0xe1 }, .rest = .{998} ++ .{0} ** 7 },
        .flags = .{ .zero = true, .parity = true },
    });
}

test "simulate flags" {
    var state = SimulatorState{};
    try assertSimulationToEqualWithState("add bx, 30000", &state, .{ .registers = .{ .ip = 4, .main = .{ 0, 0, 0, 0, 0, 0, 0x30, 0x75 } }, .flags = .{ .parity = true } });
    try assertSimulationToEqualWithState("add bx, 10000", &state, .{ .registers = .{ .ip = 4, .main = .{ 0, 0, 0, 0, 0, 0, 0x40, 0x9c } }, .flags = .{ .sign = true, .overflow = true } });
    try assertSimulationToEqualWithState("sub bx, 5000", &state, .{ .registers = .{ .ip = 4, .main = .{ 0, 0, 0, 0, 0, 0, 0xb8, 0x88 } }, .flags = .{ .parity = true, .sign = true, .auxiliary = true } });
    try assertSimulationToEqualWithState("sub bx, 5000", &state, .{ .registers = .{ .ip = 4, .main = .{ 0, 0, 0, 0, 0, 0, 0x30, 0x75 } }, .flags = .{ .parity = true, .overflow = true } });

    try assertSimulationToEqualWithState("mov bx, 1", &state, .{ .registers = .{ .ip = 3, .main = .{ 0, 0, 0, 0, 0, 0, 0x01, 0x00 } }, .flags = .{ .parity = true, .overflow = true } });
    try assertSimulationToEqualWithState("mov cx, 100", &state, .{ .registers = .{ .ip = 3, .main = .{ 0, 0, 0x64, 0, 0, 0, 0x01, 0x00 } }, .flags = .{ .parity = true, .overflow = true } });
    try assertSimulationToEqualWithState("add bx, cx", &state, .{ .registers = .{ .ip = 2, .main = .{ 0, 0, 0x64, 0, 0, 0, 0x65, 0x00 } }, .flags = .{ .parity = true } });

    try assertSimulationToEqualWithState("mov dx, 10", &state, .{ .registers = .{ .ip = 3, .main = .{ 0, 0, 0x64, 0, 0x0a, 0, 0x65, 0x00 } }, .flags = .{ .parity = true } });
    try assertSimulationToEqualWithState("sub cx, dx", &state, .{ .registers = .{ .ip = 2, .main = .{ 0, 0, 0x5a, 0, 0x0a, 0, 0x65, 0x00 } }, .flags = .{ .parity = true, .auxiliary = true } });

    try assertSimulationToEqualWithState("add bx, 40000", &state, .{ .registers = .{ .ip = 4, .main = .{ 0, 0, 0x5a, 0, 0x0a, 0, 0xa5, 0x9c } }, .flags = .{ .parity = true, .sign = true } });
    try assertSimulationToEqualWithState("add cx, -90", &state, .{ .registers = .{ .ip = 3, .main = .{ 0, 0, 0x00, 0, 0x0a, 0, 0xa5, 0x9c } }, .flags = .{ .parity = true, .auxiliary = true, .carry = true, .zero = true } });

    try assertSimulationToEqualWithState("mov sp, 99", &state, .{ .registers = .{ .ip = 3, .main = .{ 0, 0, 0x00, 0, 0x0a, 0, 0xa5, 0x9c }, .rest = .{0x63} ++ .{0} ** 7 }, .flags = .{ .parity = true, .auxiliary = true, .carry = true, .zero = true } });
    try assertSimulationToEqualWithState("mov bp, 98", &state, .{ .registers = .{ .ip = 3, .main = .{ 0, 0, 0x00, 0, 0x0a, 0, 0xa5, 0x9c }, .rest = .{ 0x63, 0x62 } ++ .{0} ** 6 }, .flags = .{ .parity = true, .auxiliary = true, .carry = true, .zero = true } });
    try assertSimulationToEqualWithState("cmp bp, sp", &state, .{ .registers = .{ .ip = 2, .main = .{ 0, 0, 0x00, 0, 0x0a, 0, 0xa5, 0x9c }, .rest = .{ 0x63, 0x62 } ++ .{0} ** 6 }, .flags = .{ .parity = true, .auxiliary = true, .carry = true, .sign = true } });
}

const memory = @import("memory.zig");
const RandomAccessMemory = memory.RandomAccessMemory;
const memory_size = RandomAccessMemory.memory_size;

test "simulate memory" {
    try assertSimulationToEqual(
        \\mov word [1000], 1
        \\mov word [1002], 2
        \\mov word [1004], 3
        \\mov word [1006], 4
        \\
        \\mov bx, 1000
        \\mov word [bx + 4], 10
        \\
        \\mov bx, word [1000]
        \\mov cx, word [1002]
        \\mov dx, word [1004]
        \\mov bp, word [1006]
    , .{ .registers = .{
        .ip = 48,
        .main = .{ 0, 0, 2, 0, 10, 0, 1, 0 },
        .rest = .{ 0, 4 } ++ .{0} ** 6,
    } });
}

test "simulate memory loop 1" {
    try assertSimulationToEqual(
        \\mov dx, 6
        \\mov bp, 1000
        \\
        \\mov si, 0
        \\init_loop_start:
        \\    mov word [bp + si], si
        \\    add si, 2
        \\    cmp si, dx
        \\    jnz init_loop_start
        \\
        \\mov bx, 0
        \\mov si, 0
        \\add_loop_start:
        \\    mov cx, word [bp + si]
        \\    add bx, cx
        \\    add si, 2
        \\    cmp si, dx
        \\    jnz add_loop_start
    , .{
        .registers = .{
            .ip = 35,
            .main = .{ 0, 0, 4, 0, 6, 0, 6, 0 },
            .rest = .{ 0, 1000, 6 } ++ .{0} ** 5,
        },
        .flags = .{ .parity = true, .zero = true },
    });
}
