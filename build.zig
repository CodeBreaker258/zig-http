// filepath: /Users/coltonsteinbeck/dev/zig-http/build.zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{});

    const exe = b.addExecutable("zig-http", "main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);

    // Link against the C standard library if necessary
    exe.linkSystemLibrary("c");

    // Define the install directory (optional)
    exe.install();

    // Default step
    b.default_step.dependOn(&exe.step);
}
