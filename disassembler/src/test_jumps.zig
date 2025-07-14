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
