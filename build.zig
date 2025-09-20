const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // raylib-zig dependency
    const raylib_zig_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
    });

    const raylib_mod = raylib_zig_dep.module("raylib");
    const raygui_mod = raylib_zig_dep.module("raygui");
    const raylib_art = raylib_zig_dep.artifact("raylib");

    // Main exe
    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // ZLS build checking module
    const exe_check = b.addExecutable(.{
        .name = "zoids",
        .root_module = exe_mod,
    });

    const exe = b.addExecutable(.{
        .name = "zoids",
        .root_module = exe_mod,
    });

    // raylib-zig linking
    exe.linkLibrary(raylib_art);
    exe.root_module.addImport("raylib", raylib_mod);
    exe.root_module.addImport("raygui", raygui_mod);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const check_step = b.step("check", "Checking if zoids compiles");
    check_step.dependOn(&exe_check.step);
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
