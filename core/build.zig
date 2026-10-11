// Sweef Browser - Zig Build Script
// Minimal build configuration for Sweef browser core engine.
// Compatible with Zig 0.11.0+

const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Create the main module
    const module = b.addModule("sweef", .{
        .source_file = .{ .path = "src/main.zig" },
    });

    // Add submodules as imports
    const http_module = b.addModule("sweef.http", .{
        .source_file = .{ .path = "src/http/client.zig" },
    });
    module.addImport("http", http_module);

    const dom_module = b.addModule("sweef.dom", .{
        .source_file = .{ .path = "src/dom/tree.zig" },
    });
    module.addImport("dom", dom_module);

    const html_module = b.addModule("sweef.html", .{
        .source_file = .{ .path = "src/html/parser.zig" },
    });
    module.addImport("html", html_module);

    const js_module = b.addModule("sweef.js", .{
        .source_file = .{ .path = "src/js/engine.zig" },
    });
    module.addImport("js", js_module);

    const mcp_module = b.addModule("sweef.mcp", .{
        .source_file = .{ .path = "src/mcp/server.zig" },
    });
    module.addImport("mcp", mcp_module);

    const ipc_module = b.addModule("sweef.ipc", .{
        .source_file = .{ .path = "src/ipc/ipc.zig" },
    });
    module.addImport("ipc", ipc_module);

    const utils_module = b.addModule("sweef.utils", .{
        .source_file = .{ .path = "src/utils/logger.zig" },
    });
    module.addImport("utils", utils_module);

    // Executable
    const exe = b.addExecutable(.{
        .name = "sweef",
        .root_module = module,
        .target = target,
        .optimize = optimize,
    });

    // Install the executable
    b.installArtifact(exe);

    // Test executable
    const test_module = b.addModule("sweef-test", .{
        .source_file = .{ .path = "src/test.zig" },
    });
    test_module.addImport("sweef", module);

    const test_exe = b.addExecutable(.{
        .name = "sweef-test",
        .root_module = test_module,
        .target = target,
        .optimize = optimize,
    });

    // Run tests as a step
    const run_tests = b.addRunArtifact(test_exe);
    run_tests.step.dependOn(&exe.step);

    const test_step = b.step("test", "Run Sweef tests");
    test_step.dependOn(&run_tests.step);
}
