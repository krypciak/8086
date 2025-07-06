const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const disassembler_mod = b.addModule("disassembler", .{
        .root_source_file = b.path("src/disassembler/disassembler.zig"),
    });

    const main_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    main_mod.addImport("disassembler", disassembler_mod);

    const main_exe = b.addExecutable(.{
        .name = "disassembler",
        .root_module = main_mod,
    });

    b.installArtifact(main_exe);

    const run_cmd = b.addRunArtifact(main_exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const test_mod = b.createModule(.{
        .root_source_file = b.path("src/test/test.zig"),
        .target = target,
        .optimize = optimize,
    });
    test_mod.addImport("disassembler", disassembler_mod);
    const main_unit_tests = b.addTest(.{
        .root_module = test_mod,
    });
    const run_unit_tests = b.addRunArtifact(main_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
