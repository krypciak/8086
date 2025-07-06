const std = @import("std");
const expect = std.testing.expect;
const process = std.process;
const disassembler = @import("main.zig");

pub fn spawnShellProcess(allocator: std.mem.Allocator, command: []const []const u8) ![]const u8 {
    var child = std.process.Child.init(command, allocator);
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Pipe;
    try child.spawn();

    var child_stdout = try std.ArrayListUnmanaged(u8).initCapacity(allocator, 100);
    var child_stderr = try std.ArrayListUnmanaged(u8).initCapacity(allocator, 100);

    try child.collectOutput(allocator, &child_stdout, &child_stderr, 100);

    const stdout_str = try child_stdout.toOwnedSlice(allocator);
    const stderr_str = try child_stderr.toOwnedSlice(allocator);

    // std.debug.print("stdout: {s}\n", .{stdout_str});
    // std.debug.print("stderr: {s}\n", .{stderr_str});
    std.debug.assert(stderr_str.len == 0);
    allocator.free(stderr_str);

    _ = try child.wait();

    return stdout_str;
}

fn assemble(allocator: std.mem.Allocator, assembly: []const u8) ![]const u8 {
    const tmp_file_path_raw = try spawnShellProcess(allocator, &[_][]const u8{ "mktemp", "--suffix", ".asm" });
    defer allocator.free(tmp_file_path_raw);
    const tmp_file_path = tmp_file_path_raw[0 .. tmp_file_path_raw.len - 1];
    // std.debug.print("tmp: {s}\n", .{tmp_file_path});

    const tmp_file = try std.fs.cwd().openFile(tmp_file_path, .{ .mode = .write_only });

    try tmp_file.writeAll("bits 16\n");
    try tmp_file.writeAll(assembly);
    tmp_file.close();

    const assembled = try spawnShellProcess(allocator, &[_][]const u8{ "nasm", tmp_file_path, "-o", "/dev/stdout" });

    return assembled;
}

fn assertInstructionDisassembly(assembly: []const u8) !void {
    const assembled = try assemble(std.testing.allocator, assembly);
    defer std.testing.allocator.free(assembled);

    const inst = try disassembler.nextInstruction(assembled, 0);
    const disassambled_inst = inst.str;
    try std.testing.expectEqualStrings(assembly, disassambled_inst);
}

test "mov reg to reg" {
    try assertInstructionDisassembly("mov ax, bx");
}
