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

        pub fn to_string(self: *const Type) []const u8 {
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

    pub fn to_string(self: *const Jump, allocator: std.mem.Allocator) ![]const u8 {
        const p1 = self.type.to_string();

        return std.fmt.allocPrint(allocator, "{s} {d}", .{p1, self.offset});
    }

    pub fn execute(self: *const Jump) !void {
        _ = self;
    }
};

pub fn conditional_jump(data: []const u8, at: usize, jumpType: Jump.Type) !Instruction {
    const b2: i8 = @bitCast(data[at + 1]);
    return Instruction{ .len = 2, .inst = .{ .Jump = .{ .type = jumpType, .offset = b2 } } };
}

const testing = @import("test.zig");

test "conditional jumps" {
    try testing.assertDisassemblyToEqual("je label", "je -2");
    try testing.assertDisassemblyToEqual("jl label", "jl -2");
    try testing.assertDisassemblyToEqual("jle label", "jle -2");
    try testing.assertDisassemblyToEqual("jb label", "jb -2");
    try testing.assertDisassemblyToEqual("jbe label", "jbe -2");
    try testing.assertDisassemblyToEqual("jp label", "jp -2");
    try testing.assertDisassemblyToEqual("jo label", "jo -2");
    try testing.assertDisassemblyToEqual("js label", "js -2");
    try testing.assertDisassemblyToEqual("jne label", "jne -2");
    try testing.assertDisassemblyToEqual("jnl label", "jnl -2");
    try testing.assertDisassemblyToEqual("jnle label", "jnle -2");
    try testing.assertDisassemblyToEqual("jnb label", "jnb -2");
    try testing.assertDisassemblyToEqual("jnbe label", "jnbe -2");
    try testing.assertDisassemblyToEqual("jnp label", "jnp -2");
    try testing.assertDisassemblyToEqual("jno label", "jno -2");
    try testing.assertDisassemblyToEqual("jns label", "jns -2");
    try testing.assertDisassemblyToEqual("loop label", "loop -2");
    try testing.assertDisassemblyToEqual("loopz label", "loopz -2");
    try testing.assertDisassemblyToEqual("loopnz label", "loopnz -2");
    try testing.assertDisassemblyToEqual("jcxz label", "jcxz -2");
}
