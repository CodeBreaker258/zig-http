const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const xev = b.dependency("libxev", .{ .target = target, .optimize = optimize });
    const exe = b.addExecutable(.{
        .name = "xev-http",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    // Link the xev library to the executable
    exe.linkLibrary(xev.lib_path());

    // Specify the executable installation step
    exe.install();

    // Ensure the default build step depends on building the executable
    b.default_step.dependOn(&exe.step);
}
