// Sweef Browser - Zig Build Script
// Minimal build configuration for Sweef browser core engine.
// Compatible with Zig 0.11.0+

const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Options
    const options = b.addOptions();
    options.addOption(bool, "no-js", false, "Disable JavaScript support");
    options.addOption(bool, "no-gui", false, "Disable GUI support");
    options.addOption(bool, "no-tls", false, "Disable TLS/HTTPS support");

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

    // QuickJS C library
    if (!b.option(options, "no-js", bool)) {
        module.addIncludePath(.{ .path = "../quickjs" });

        const quickjs_c_files = &[_][]const u8{
            "../quickjs/quickjs.c",
            "../quickjs/libregexp.c",
            "../quickjs/libunicode.c",
            "../quickjs/cutils.c",
            "../quickjs/dtoa.c",
            "../quickjs/quickjs-libc.c",
        };

        for (quickjs_c_files) |c_file| {
            module.addCSourceFile(.{
                .file = .{ .path = c_file },
                .flags = &.{" -D_CONFIG_H_"},
            });
        }

        module.linkLibC();
        module.linkLibM();
    }

    // SDL2 for GUI (optional)
    if (!b.option(options, "no-gui", bool)) {
        module.linkLibrary("SDL2");
        module.linkLibrary("SDL2_image");
        module.linkLibrary("SDL2_ttf");
    }

    // mbedTLS for HTTPS (optional)
    if (!b.option(options, "no-tls", bool)) {
        module.linkLibrary("mbedtls");
        module.linkLibrary("mbedx509");
        module.linkLibrary("mbedcrypto");
    }

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
