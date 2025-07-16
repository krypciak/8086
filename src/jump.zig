const std = @import("std");

const instruciton = @import("instruction.zig");
const Instruction = instruciton.Instruction;

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

        return std.fmt.allocPrint(allocator, "{s} {d}", .{p1, self.offset});
    }

    pub fn execute(self: *const Jump) !void {
        _ = self;
    }
};

pub fn conditionalJump(data: []const u8, at: usize, jumpType: Jump.Type) !Instruction {
    const b2: i8 = @bitCast(data[at + 1]);
    return Instruction{ .len = 2, .inst = .{ .Jump = .{ .type = jumpType, .offset = b2 } } };
}

const disassembler = @import("disassembler.zig");

test "conditional jumps" {
    try disassembler.assertDisassemblyToEqual("je label", "je -2");
    try disassembler.assertDisassemblyToEqual("jl label", "jl -2");
    try disassembler.assertDisassemblyToEqual("jle label", "jle -2");
    try disassembler.assertDisassemblyToEqual("jb label", "jb -2");
    try disassembler.assertDisassemblyToEqual("jbe label", "jbe -2");
    try disassembler.assertDisassemblyToEqual("jp label", "jp -2");
    try disassembler.assertDisassemblyToEqual("jo label", "jo -2");
    try disassembler.assertDisassemblyToEqual("js label", "js -2");
    try disassembler.assertDisassemblyToEqual("jne label", "jne -2");
    try disassembler.assertDisassemblyToEqual("jnl label", "jnl -2");
    try disassembler.assertDisassemblyToEqual("jnle label", "jnle -2");
    try disassembler.assertDisassemblyToEqual("jnb label", "jnb -2");
    try disassembler.assertDisassemblyToEqual("jnbe label", "jnbe -2");
    try disassembler.assertDisassemblyToEqual("jnp label", "jnp -2");
    try disassembler.assertDisassemblyToEqual("jno label", "jno -2");
    try disassembler.assertDisassemblyToEqual("jns label", "jns -2");
    try disassembler.assertDisassemblyToEqual("loop label", "loop -2");
    try disassembler.assertDisassemblyToEqual("loopz label", "loopz -2");
    try disassembler.assertDisassemblyToEqual("loopnz label", "loopnz -2");
    try disassembler.assertDisassemblyToEqual("jcxz label", "jcxz -2");
}
