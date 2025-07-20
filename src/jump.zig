const std = @import("std");

const instruciton = @import("instruction.zig");
const Instruction = instruciton.Instruction;

const simulator = @import("simulator.zig");
const SimulatorState = simulator.SimulatorState;

const memory = @import("memory.zig");
const RegisterMemory = memory.RegisterMemory;

pub const Jump = struct {
    pub const Type = enum {
        je,
        jl,
        jle,
        jb,
        jbe,
        jp,
        jo,
        js,
        jne,
        jnl,
        jnle,
        jnb,
        jnbe,
        jnp,
        jno,
        jns,
        loop,
        loopz,
        loopnz,
        jcxz,

        pub fn toString(self: *const Type) []const u8 {
            return switch (self.*) {
                .je => "je",
                .jl => "jl",
                .jle => "jle",
                .jb => "jb",
                .jbe => "jbe",
                .jp => "jp",
                .jo => "jo",
                .js => "js",
                .jne => "jne",
                .jnl => "jnl",
                .jnle => "jnle",
                .jnb => "jnb",
                .jnbe => "jnbe",
                .jnp => "jnp",
                .jno => "jno",
                .jns => "jns",
                .loop => "loop",
                .loopz => "loopz",
                .loopnz => "loopnz",
                .jcxz => "jcxz",
            };
        }
    };

    type: Type,
    offset: i8,

    pub fn toString(self: *const Jump, allocator: std.mem.Allocator) ![]const u8 {
        const p1 = self.type.toString();

        const display_value = self.offset + 2;
        const sign: u8 = if (display_value >= 0) '+' else '-';
        return std.fmt.allocPrint(allocator, "{s} ${c}{d}", .{ p1, sign, @abs(display_value) });
    }

    pub fn execute(self: *const Jump, state: *SimulatorState) void {
        const condition_passed = switch (self.type) {
            .je => state.flags.zero,
            // .jl
            // .jle
            .jb => state.flags.carry,
            // jbe
            .jp => state.flags.parity,
            .js => state.flags.sign,
            .jne => !state.flags.zero,
            // .jnl
            // .jnle
            // .jnb
            // .jnbe
            // .jnp
            // .jno
            // .jns
            // .loop
            // .loopz
            .loopnz => blk: {
                const value = state.registers.getValueWord(.CX);
                const new_value: u16 = value - 1;
                state.registers.setValueWord(.CX, new_value);
                if (new_value >= std.math.maxInt(u16) - 20) unreachable;
                break :blk new_value != 0 and !state.flags.zero;
            },
            // .jcxz
            else => unreachable,
        };

        if (condition_passed) {
            state.registers.ip +%= @bitCast(@as(i16, self.offset));
        }
    }

    pub fn estimateCycles(self: *const Jump) ?u8 {
        _ = self;
        return null;
    }
};

pub fn conditionalJump(data: []const u8, at: usize, jumpType: Jump.Type) !Instruction {
    const b2: i8 = @bitCast(data[at + 1]);
    const offset: i8 = b2;

    return Instruction{ .len = 2, .inst = .{ .Jump = .{ .type = jumpType, .offset = offset } } };
}

const disassembler = @import("disassembler.zig");

test "disassembler conditional jumps 1" {
    try disassembler.assertDisassemblyToEqual("je label", "je $+0");
}
test "disassembler conditional jumps 2" {
    try disassembler.assertDisassemblyToEqual("jl label", "jl $+0");
}
test "disassembler conditional jumps 3" {
    try disassembler.assertDisassemblyToEqual("jle label", "jle $+0");
}
test "disassembler conditional jumps 4" {
    try disassembler.assertDisassemblyToEqual("jb label", "jb $+0");
}
test "disassembler conditional jumps 5" {
    try disassembler.assertDisassemblyToEqual("jbe label", "jbe $+0");
}
test "disassembler conditional jumps 6" {
    try disassembler.assertDisassemblyToEqual("jp label", "jp $+0");
}
test "disassembler conditional jumps 7" {
    try disassembler.assertDisassemblyToEqual("jo label", "jo $+0");
}
test "disassembler conditional jumps 8" {
    try disassembler.assertDisassemblyToEqual("js label", "js $+0");
}
test "disassembler conditional jumps 9" {
    try disassembler.assertDisassemblyToEqual("jne label", "jne $+0");
}
test "disassembler conditional jumps 10" {
    try disassembler.assertDisassemblyToEqual("jnl label", "jnl $+0");
}
test "disassembler conditional jumps 11" {
    try disassembler.assertDisassemblyToEqual("jnle label", "jnle $+0");
}
test "disassembler conditional jumps 12" {
    try disassembler.assertDisassemblyToEqual("jnb label", "jnb $+0");
}
test "disassembler conditional jumps 13" {
    try disassembler.assertDisassemblyToEqual("jnbe label", "jnbe $+0");
}
test "disassembler conditional jumps 14" {
    try disassembler.assertDisassemblyToEqual("jnp label", "jnp $+0");
}
test "disassembler conditional jumps 15" {
    try disassembler.assertDisassemblyToEqual("jno label", "jno $+0");
}
test "disassembler conditional jumps 16" {
    try disassembler.assertDisassemblyToEqual("jns label", "jns $+0");
}
test "disassembler conditional jumps 17" {
    try disassembler.assertDisassemblyToEqual("loop label", "loop $+0");
}
test "disassembler conditional jumps 18" {
    try disassembler.assertDisassemblyToEqual("loopz label", "loopz $+0");
}
test "disassembler conditional jumps 19" {
    try disassembler.assertDisassemblyToEqual("loopnz label", "loopnz $+0");
}
test "disassembler conditional jumps 20" {
    try disassembler.assertDisassemblyToEqual("jcxz label", "jcxz $+0");
}

test "simulator ip register" {
    try simulator.assertSimulationToEqual(
        \\mov cx, 200
        \\mov bx, cx
        \\add cx, 1000
        \\mov bx, 2000
        \\sub cx, bx
    , .{ .registers = .{ .ip = 14, .main = .{ 0, 0, 0xe0, 0xfc, 0, 0, 0xd0, 0x07 } }, .flags = .{ .carry = true, .sign = true } });

    try simulator.assertSimulationToEqual(
        \\mov cx, 3
        \\mov bx, 1000
        \\loop_start:
        \\add bx, 10
        \\sub cx, 1
        \\jnz loop_start
    , .{ .registers = .{ .ip = 14, .main = .{ 0, 0, 0, 0, 0, 0, 0x06, 0x04 } }, .flags = .{ .parity = true, .zero = true } });
}

test "simulator jump loops" {
    try simulator.assertSimulationToEqual(
        \\mov ax, 10
        \\mov bx, 10
        \\mov cx, 10
        \\
        \\label_0:
        \\cmp bx, cx
        \\je label_1
        \\
        \\add ax, 1
        \\jp label_2
        \\
        \\label_1:
        \\sub bx, 5
        \\jb label_3
        \\
        \\label_2:
        \\sub cx, 2
        \\
        \\label_3:
        \\loopnz label_0
    , .{ .registers = .{
        .ip = 28,
        .main = .{ 13, 0, 0, 0, 0, 0, 0xfb, 0xff },
    }, .flags = .{ .carry = true, .auxiliary = true, .sign = true } });
}
