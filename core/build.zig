// Sweef Browser - Zig Build Script
// This is the main build file for the Sweef browser core engine.

const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Sweef core module
    const sweef_module = b.addModule("sweef", .{
        .source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    // HTTP module
    const http_module = b.addModule("sweef.http", .{
        .source_file = .{ .path = "src/http/client.zig" },
        .target = target,
        .optimize = optimize,
    });
    sweef_module.addImport("http", http_module);

    // DOM module
    const dom_module = b.addModule("sweef.dom", .{
        .source_file = .{ .path = "src/dom/tree.zig" },
        .target = target,
        .optimize = optimize,
    });
    sweef_module.addImport("dom", dom_module);

    // HTML module (GUMBO wrapper)
    const html_module = b.addModule("sweef.html", .{
        .source_file = .{ .path = "src/html/parser.zig" },
        .target = target,
        .optimize = optimize,
    });
    sweef_module.addImport("html", html_module);

    // JavaScript module (QuickJS wrapper)
    const js_module = b.addModule("sweef.js", .{
        .source_file = .{ .path = "src/js/engine.zig" },
        .target = target,
        .optimize = optimize,
    });
    sweef_module.addImport("js", js_module);

    // MCP module
    const mcp_module = b.addModule("sweef.mcp", .{
        .source_file = .{ .path = "src/mcp/server.zig" },
        .target = target,
        .optimize = optimize,
    });
    sweef_module.addImport("mcp", mcp_module);

    // IPC module
    const ipc_module = b.addModule("sweef.ipc", .{
        .source_file = .{ .path = "src/ipc/ipc.zig" },
        .target = target,
        .optimize = optimize,
    });
    sweef_module.addImport("ipc", ipc_module);

    // Utils module
    const utils_module = b.addModule("sweef.utils", .{
        .source_file = .{ .path = "src/utils/logger.zig" },
        .target = target,
        .optimize = optimize,
    });
    sweef_module.addImport("utils", utils_module);

    // QuickJS C library
    const quickjs_options = b.addOptions();
    quickjs_options.addOption(bool, "no-js", false, "Disable JavaScript support");
    
    const quickjs_module = b.addModule("quickjs", .{
        .source_file = .{ .path = "../quickjs/quickjs.zig" },
        .target = target,
        .optimize = optimize,
    });
    
    // Link QuickJS only if JS is enabled
    if (!b.option(quickjs_options, "no-js", bool)) {
        sweef_module.addImport("quickjs", quickjs_module);
        
        // Add QuickJS C source files
        const quickjs_c_files = &[_][]const u8{
            "../quickjs/quickjs.c",
            "../quickjs/libregexp.c",
            "../quickjs/libunicode.c",
        };
        
        for (quickjs_c_files) |c_file| {
            sweef_module.addCSourceFile(.{
                .file = .{ .path = c_file },
                .flags = &.{" -D_CONFIG_H_"},
            });
        }
        
        // Add required C libraries
        sweef_module.linkLibC();
        sweef_module.linkLibM();
    }

    // GUMBO HTML parser
    sweef_module.addCSourceFile(.{
        .file = .{ .path = "../quickjs/gumbo.c" },
        .flags = &.{},
    });

    // SDL2 for GUI (optional)
    const gui_options = b.addOptions();
    gui_options.addOption(bool, "no-gui", false, "Disable GUI support");
    
    if (!b.option(gui_options, "no-gui", bool)) {
        sweef_module.addCSourceFile(.{
            .file = .{ .path = "src/gui/sdl.zig" },
            .flags = &.{" -DSWEEF_GUI"},
        });
        sweef_module.linkLibrary("SDL2");
        sweef_module.linkLibrary("SDL2_image");
        sweef_module.linkLibrary("SDL2_ttf");
    }

    // Network options
    const network_options = b.addOptions();
    network_options.addOption(bool, "no-tls", false, "Disable TLS/HTTPS support");
    
    if (!b.option(network_options, "no-tls", bool)) {
        // Add mbedTLS for HTTPS support
        sweef_module.addCSourceFile(.{
            .file = .{ .path = "src/http/tls.zig" },
            .flags = &.{},
        });
        sweef_module.linkLibrary("mbedtls");
        sweef_module.linkLibrary("mbedx509");
        sweef_module.linkLibrary("mbedcrypto");
    }

    // Executable
    const sweef_exe = b.addExecutable(.{
        .name = "sweef",
        .root_module = sweef_module,
        .target = target,
        .optimize = optimize,
    });

    // Install
    b.installArtifact(sweef_exe);

    // Test executable
    const test_module = b.addModule("sweef.test", .{
        .source_file = .{ .path = "src/test.zig" },
        .target = target,
        .optimize = optimize,
    });
    test_module.addImport("sweef", sweef_module);
    
    const test_exe = b.addExecutable(.{
        .name = "sweef-test",
        .root_module = test_module,
        .target = target,
        .optimize = optimize,
    });

    // Run tests
    const run_tests = b.addRunArtifact(test_exe);
    run_tests.step.dependOn(&sweef_exe.step);
    
    const test_step = b.step("test", "Run Sweef tests");
    test_step.dependOn(&run_tests.step);
}
