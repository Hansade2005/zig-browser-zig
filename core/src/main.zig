// Sweef Browser - Minimal Main Entry Point
// Ultra-lightweight browser for AI agents and humans.
// Simplified version that compiles.

const std = @import("std");

pub const SweefConfig = struct {
    headless: bool = true,
    gui: bool = false,
    debug: bool = false,
    mcp: bool = false,
    mcp_port: u16 = 3000,
    user_agent: []const u8 = "Sweef/0.1.0",
    viewport_width: u32 = 800,
    viewport_height: u32 = 600,
    timeout: u32 = 5000,
    slow_mo: u32 = 0,
    disable_js: bool = false,
    disable_css: bool = false,
    disable_images: bool = false,
    script: ?[]const u8 = null,
    url: ?[]const u8 = null,
    repl: bool = false,
};

// Minimal browser struct without external dependencies
const SweefBrowser = struct {
    config: SweefConfig,
    allocator: std.mem.Allocator,

    pub fn init(config: SweefConfig) SweefBrowser {
        return SweefBrowser{
            .config = config,
            .allocator = std.heap.page_allocator,
        };
    }

    pub fn deinit(self: *SweefBrowser) void {
        _ = self;
    }

    pub fn run(self: *SweefBrowser) !void {
        if (self.config.debug) {
            std.debug.print("Sweef Browser running with config: headless={}, gui={}, mcp={}\n", .{
                self.config.headless,
                self.config.gui,
                self.config.mcp,
            });
        }

        if (self.config.script) |script_path| {
            std.debug.print("Would run script: {s}\n", .{script_path});
        } else if (self.config.url) |url| {
            std.debug.print("Would load URL: {s}\n", .{url});
        } else if (self.config.repl) {
            std.debug.print("REPL mode not yet implemented\n", .{});
        } else if (self.config.mcp) {
            std.debug.print("MCP server mode not yet implemented\n", .{});
        } else {
            std.debug.print("Sweef Browser v0.1.0 - Ultra-lightweight browser\n", .{});
            std.debug.print("Use --help for usage information\n", .{});
        }
    }
};

fn printUsage() void {
    std.debug.print("Usage: sweef [OPTIONS]\n", .{});
    std.debug.print("  --headless    Run in headless mode (default)\n", .{});
    std.debug.print("  --gui        Run with GUI\n", .{});
    std.debug.print("  --debug      Enable debug logs\n", .{});
    std.debug.print("  --mcp        Enable MCP server for AI agents\n", .{});
    std.debug.print("  --mcp-port   MCP server port (default: 3000)\n", .{});
    std.debug.print("  --url        Open a URL on startup\n", .{});
    std.debug.print("  --script     Run a script file\n", .{});
    std.debug.print("  --repl       Start interactive REPL mode\n", .{});
    std.debug.print("  --help, -h   Show this help message\n", .{});
    std.debug.print("  --version, -v Show version\n", .{});
}

fn parseArgs() SweefConfig {
    var args_iter = std.process.args();
    var config = SweefConfig{};

    // Skip program name
    _ = args_iter.next();

    while (args_iter.next()) |arg| {
        if (std.mem.eql(u8, arg, "--headless")) {
            config.headless = true;
        } else if (std.mem.eql(u8, arg, "--gui")) {
            config.gui = true;
            config.headless = false;
        } else if (std.mem.eql(u8, arg, "--debug")) {
            config.debug = true;
        } else if (std.mem.eql(u8, arg, "--mcp")) {
            config.mcp = true;
        } else if (std.mem.eql(u8, arg, "--mcp-port")) {
            if (args_iter.next()) |port_str| {
                config.mcp_port = std.fmt.parseInt(u16, port_str, 10) catch 3000;
            }
        } else if (std.mem.eql(u8, arg, "--url")) {
            if (args_iter.next()) |url| {
                config.url = url;
            }
        } else if (std.mem.eql(u8, arg, "--script")) {
            if (args_iter.next()) |script| {
                config.script = script;
            }
        } else if (std.mem.eql(u8, arg, "--repl")) {
            config.repl = true;
        } else if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) {
            printUsage();
            std.process.exit(0);
        } else if (std.mem.eql(u8, arg, "--version") or std.mem.eql(u8, arg, "-v")) {
            std.debug.print("Sweef Browser v0.1.0\n", .{});
            std.process.exit(0);
        }
    }

    return config;
}

pub fn main() !void {
    const config = parseArgs();

    var browser = SweefBrowser.init(config);
    browser.run() catch |err| {
        std.debug.print("Error: {any}\n", .{err});
        std.process.exit(1);
    };
}
