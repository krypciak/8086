const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const disassembler_mod = b.addModule("disassembler", .{
        .root_source_file = b.path("src/disassembler.zig"),
        .target = target,
        .optimize = optimize,
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

    const clear_screen_step: *std.Build.Step = b.allocator.create(std.Build.Step) catch unreachable;
    clear_screen_step.* = std.Build.Step.init(.{
        .id = std.Build.Step.Id.custom,
        .name = "clear terminal screen",
        .owner = main_exe.step.owner,
        .makeFn = (struct {
            pub fn call(step: *std.Build.Step, options: std.Build.Step.MakeOptions) anyerror!void {
                _ = step;
                _ = options;
                std.debug.print("\x1B[2J\x1B[H", .{});
            }
        }).call,
    });
    clear_screen_step.addWatchInput(.{ .cwd_relative = "src/main.zig" }) catch unreachable;

    b.installArtifact(main_exe);

    const run_cmd = b.addRunArtifact(main_exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const main_unit_tests = b.addTest(.{
        .root_module = disassembler_mod,
    });
    main_unit_tests.step.dependOn(clear_screen_step);

    const run_unit_tests = b.addRunArtifact(main_unit_tests);

    const test_step = b.step("test", "Run unit tests");

    test_step.dependOn(&run_unit_tests.step);
}
