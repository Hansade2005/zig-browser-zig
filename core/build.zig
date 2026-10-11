// Sweef Browser - Zig Build Script
// Minimal build configuration for Sweef browser core engine.
// Compatible with Zig 0.11.0+

const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Create the main executable
    const exe = b.addExecutable(.{
        .name = "sweef",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    // Install the executable
    b.installArtifact(exe);

    // Test step
    const test_step = b.step("test", "Run Sweef tests");
    test_step.dependOn(&exe.step);
}
