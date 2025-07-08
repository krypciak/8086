const testing = @import("test.zig");

test "conditional jumps" {
    try testing.assertInstructionDisassemblyToEqual("je label", "je -2");
    try testing.assertInstructionDisassemblyToEqual("jl label", "jl -2");
    try testing.assertInstructionDisassemblyToEqual("jle label", "jle -2");
    try testing.assertInstructionDisassemblyToEqual("jb label", "jb -2");
    try testing.assertInstructionDisassemblyToEqual("jbe label", "jbe -2");
    try testing.assertInstructionDisassemblyToEqual("jp label", "jp -2");
    try testing.assertInstructionDisassemblyToEqual("jo label", "jo -2");
    try testing.assertInstructionDisassemblyToEqual("js label", "js -2");
    try testing.assertInstructionDisassemblyToEqual("jne label", "jne -2");
    try testing.assertInstructionDisassemblyToEqual("jnl label", "jnl -2");
    try testing.assertInstructionDisassemblyToEqual("jnle label", "jnle -2");
    try testing.assertInstructionDisassemblyToEqual("jnb label", "jnb -2");
    try testing.assertInstructionDisassemblyToEqual("jnbe label", "jnbe -2");
    try testing.assertInstructionDisassemblyToEqual("jnp label", "jnp -2");
    try testing.assertInstructionDisassemblyToEqual("jno label", "jno -2");
    try testing.assertInstructionDisassemblyToEqual("jns label", "jns -2");
    try testing.assertInstructionDisassemblyToEqual("loop label", "loop -2");
    try testing.assertInstructionDisassemblyToEqual("loopz label", "loopz -2");
    try testing.assertInstructionDisassemblyToEqual("loopnz label", "loopnz -2");
    try testing.assertInstructionDisassemblyToEqual("jcxz label", "jcxz -2");
}
