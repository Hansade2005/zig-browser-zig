// Sweef Browser - Main Entry Point
// The ultra-lightweight browser for AI agents and humans.

const std = @import("std");
const http = @import("http");
const dom = @import("dom");
const html = @import("html");
const js = @import("js");
const mcp = @import("mcp");
const ipc = @import("ipc");
const utils = @import("utils");

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

pub const SweefBrowser = struct {
    config: SweefConfig,
    allocator: std.mem.Allocator,
    http_client: *http.HttpClient,
    js_engine: ?*js.JSEngine,
    mcp_server: ?*mcp.MCPServer,
    ipc_server: ?*ipc.IPCServer,
    current_page: ?*Page,
    pages: std.ArrayList(*Page),

    pub fn init(config: SweefConfig) !*SweefBrowser {
        var browser = SweefBrowser{
            .config = config,
            .allocator = std.heap.page_allocator,
            .http_client = try http.HttpClient.init(config.user_agent),
            .js_engine = if (!config.disable_js) js.JSEngine.init() else null,
            .mcp_server = null,
            .ipc_server = null,
            .current_page = null,
            .pages = .{},
        };

        // Initialize MCP server if enabled
        if (config.mcp) {
            browser.mcp_server = try mcp.MCPServer.init(&browser, config.mcp_port);
        }

        // Initialize IPC server for SDKs
        browser.ipc_server = try ipc.IPCServer.init(&browser);

        return &browser;
    }

    pub fn deinit(self: *SweefBrowser) void {
        if (self.mcp_server) |server| {
            server.deinit();
        }
        if (self.ipc_server) |server| {
            server.deinit();
        }
        if (self.js_engine) |engine| {
            engine.deinit();
        }
        self.http_client.deinit();
        for (self.pages.items) |page| {
            page.deinit();
        }
        self.pages.deinit(self.allocator);
    }

    pub fn newPage(self: *SweefBrowser) !*Page {
        var page = try Page.init(self, self.config);
        try self.pages.append(page);
        self.current_page = page;
        return page;
    }

    pub fn closePage(self: *SweefBrowser, page: *Page) void {
        page.deinit();
        for (self.pages.items) |p, i| {
            if (p == page) {
                _ = self.pages.remove(i);
                break;
            }
        }
        if (self.current_page == page) {
            self.current_page = null;
        }
    }

    pub fn run(self: *SweefBrowser) !void {
        // Handle script mode
        if (self.config.script) |script_path| {
            return self.runScript(script_path);
        }

        // Handle URL mode
        if (self.config.url) |url| {
            const page = try self.newPage();
            try page.goto(url);
            return;
        }

        // Handle REPL mode
        if (self.config.repl) {
            return self.runRepl();
        }

        // Handle GUI mode
        if (self.config.gui) {
            return self.runGui();
        }

        // Default: Start MCP server (for AI agents)
        if (self.config.mcp) {
            std.debug.print("Sweef MCP Server running on port {d}\n", .{self.config.mcp_port});
            try self.mcp_server.?.run();
            return;
        }

        // Default: Start IPC server (for SDKs)
        std.debug.print("Sweef Browser running in headless mode. Use SDKs to connect.\n", .{});
        try self.ipc_server.?.run();
    }

    pub fn runScript(self: *SweefBrowser, script_path: []const u8) !void {
        const script_content = try std.fs.cwd().readFileAlloc(self.allocator, script_path, std.fs.File.ReadFlags{});
        defer self.allocator.free(script_content);

        // Detect script type
        if (std.mem.endsWith(u8, script_path, ".js")) {
            // JavaScript script
            const page = try self.newPage();
            try page.evaluate(script_content);
        } else if (std.mem.endsWith(u8, script_path, ".py")) {
            // Python script (pass to Python SDK)
            std.debug.print("Python scripts must be run with the Python SDK.\n", .{});
        } else {
            // Assume Node.js script
            const page = try self.newPage();
            try page.evaluate(script_content);
        }
    }

    pub fn runRepl(self: *SweefBrowser) !void {
        std.debug.print("Sweef REPL Mode. Type 'help' for commands.\n", .{});

        const stdin = std.io.getStdIn().reader();
        const stdout = std.io.getStdOut().writer();

        var buffer: [1024]u8 = undefined;
        while (true) {
            stdout.print("> ", .{});
            try stdout.flush();

            const line = try stdin.readUntilDelimiterOrEofAlloc(self.allocator, '\n', 1024);
            defer self.allocator.free(line);

            if (std.mem.eql(u8, line, "exit")) {
                break;
            } else if (std.mem.eql(u8, line, "help")) {
                stdout.print("Commands:\n", .{});
                stdout.print("  goto <url> - Navigate to URL\n", .{});
                stdout.print("  click <selector> - Click element\n", .{});
                stdout.print("  type <selector> <text> - Type into input\n", .{});
                stdout.print("  evaluate <js> - Run JavaScript\n", .{});
                stdout.print("  screenshot <path> - Take screenshot\n", .{});
                stdout.print("  get_dom - Get DOM as JSON\n", .{});
                stdout.print("  get_network_logs - Get network logs\n", .{});
                stdout.print("  clear_logs - Clear logs\n", .{});
                stdout.print("  exit - Exit REPL\n", .{});
                try stdout.flush();
            } else if (std.mem.startsWith(u8, line, "goto ")) {
                const url = line[5..];
                const page = try self.newPage();
                try page.goto(url);
                stdout.print("Navigated to {s}\n", .{url});
                try stdout.flush();
            } else if (std.mem.startsWith(u8, line, "click ")) {
                const selector = line[6..];
                if (self.current_page) |page| {
                    try page.click(selector);
                    stdout.print("Clicked {s}\n", .{selector});
                    try stdout.flush();
                } else {
                    stdout.print("Error: No active page. Use 'goto' first.\n", .{});
                    try stdout.flush();
                }
            } else if (std.mem.startsWith(u8, line, "type ")) {
                const parts = std.mem.split(u8, line[5..], " ");
                if (parts.len >= 2) {
                    const selector = parts[0];
                    const text = std.mem.join(u8, parts[1..], " ");
                    if (self.current_page) |page| {
                        try page.type(selector, text);
                        stdout.print("Typed '{s}' into {s}\n", .{ text, selector });
                        try stdout.flush();
                    } else {
                        stdout.print("Error: No active page. Use 'goto' first.\n", .{});
                        try stdout.flush();
                    }
                }
            } else if (std.mem.startsWith(u8, line, "evaluate ")) {
                const js = line[9..];
                if (self.current_page) |page| {
                    const result = try page.evaluate(js);
                    stdout.print("Result: {s}\n", .{result});
                    try stdout.flush();
                } else {
                    stdout.print("Error: No active page. Use 'goto' first.\n", .{});
                    try stdout.flush();
                }
            } else if (std.mem.startsWith(u8, line, "screenshot ")) {
                const path = line[11..];
                if (self.current_page) |page| {
                    try page.screenshot(path);
                    stdout.print("Screenshot saved to {s}\n", .{path});
                    try stdout.flush();
                } else {
                    stdout.print("Error: No active page. Use 'goto' first.\n", .{});
                    try stdout.flush();
                }
            } else if (std.mem.eql(u8, line, "get_dom")) {
                if (self.current_page) |page| {
                    const dom = try page.getDom();
                    stdout.print("{s}\n", .{dom});
                    try stdout.flush();
                } else {
                    stdout.print("Error: No active page. Use 'goto' first.\n", .{});
                    try stdout.flush();
                }
            } else if (std.mem.eql(u8, line, "get_network_logs")) {
                if (self.current_page) |page| {
                    const logs = try page.getNetworkLogs();
                    stdout.print("{s}\n", .{logs});
                    try stdout.flush();
                } else {
                    stdout.print("Error: No active page. Use 'goto' first.\n", .{});
                    try stdout.flush();
                }
            } else if (std.mem.eql(u8, line, "clear_logs")) {
                if (self.current_page) |page| {
                    page.clearLogs();
                    stdout.print("Logs cleared.\n", .{});
                    try stdout.flush();
                } else {
                    stdout.print("Error: No active page. Use 'goto' first.\n", .{});
                    try stdout.flush();
                }
            } else if (std.mem.trim(u8, line, " ").len > 0) {
                stdout.print("Unknown command: {s}. Type 'help' for commands.\n", .{line});
                try stdout.flush();
            }
        }
    }

    pub fn runGui(self: *SweefBrowser) !void {
        @compileError("GUI mode not implemented yet. Use --no-gui flag to disable.");
    }
};

pub const Page = struct {
    browser: *SweefBrowser,
    url: []const u8,
    html: []const u8,
    dom: ?*dom.DOMNode,
    js_context: ?*js.JSContext,
    network_logs: std.ArrayList(http.NetworkLog),
    console_logs: std.ArrayList(utils.ConsoleLog),

    pub fn init(browser: *SweefBrowser, config: SweefConfig) !*Page {
        var page = Page{
            .browser = browser,
            .url = "",
            .html = "",
            .dom = null,
            .js_context = if (!config.disable_js) browser.js_engine.?.newContext() else null,
            .network_logs = .{},
            .console_logs = .{},
        };
        return &page;
    }

    pub fn deinit(self: *Page) void {
        if (self.js_context) |ctx| {
            ctx.deinit();
        }
        if (self.dom) |d| {
            d.deinit();
        }
        self.network_logs.deinit(self.browser.allocator);
        self.console_logs.deinit(self.browser.allocator);
        self.browser.allocator.free(self.html);
    }

    pub fn goto(self: *Page, url: []const u8) !void {
        const response = try self.browser.http_client.get(url);
        self.url = try self.browser.allocator.dupe(u8, url);
        self.html = try self.browser.allocator.dupe(u8, response.body);

        // Parse HTML
        self.dom = try html.parse(self.html);

        // Log network request
        try self.network_logs.append(.{
            .url = url,
            .method = "GET",
            .status = response.status,
            .headers = response.headers,
            .body = response.body,
        });

        if (self.browser.config.debug) {
            std.debug.print("Navigated to {s} (Status: {d})\n", .{ url, response.status });
        }

        // If JS is enabled, set up DOM bindings
        if (self.js_context) |ctx| {
            try js.setupDOMBindings(ctx, self.dom.?);
        }
    }

    pub fn click(self: *Page, selector: []const u8) !void {
        if (self.dom) |d| {
            const node = try d.querySelector(selector);
            if (node == null) {
                return error.ElementNotFound;
            }

            // Simulate click
            if (self.browser.config.debug) {
                std.debug.print("Clicked {s}\n", .{selector});
            }

            // Handle navigation if it's a link
            if (std.mem.eql(u8, node.tagName, "a")) {
                if (node.attributes.get("href")) |href| {
                    try self.goto(href);
                }
            }
        } else {
            return error.NoDOM;
        }
    }

    pub fn type(self: *Page, selector: []const u8, text: []const u8) !void {
        if (self.dom) |d| {
            const node = try d.querySelector(selector);
            if (node == null) {
                return error.ElementNotFound;
            }

            if (self.browser.config.debug) {
                std.debug.print("Typed '{s}' into {s}\n", .{ text, selector });
            }

            // In a real implementation, we'd update the DOM
            // For now, just log it
        } else {
            return error.NoDOM;
        }
    }

    pub fn evaluate(self: *Page, js: []const u8) ![]const u8 {
        if (!self.js_context) |_| {
            return error.JSDisabled;
        }

        const ctx = self.js_context.?;
        const result = try ctx.evaluate(js);

        if (self.browser.config.debug) {
            std.debug.print("JS Evaluation: {s}\n", .{js});
        }

        return result;
    }

    pub fn getDom(self: *Page) ![]const u8 {
        if (self.dom) |d| {
            return try d.toJson(self.browser.allocator);
        } else {
            return error.NoDOM;
        }
    }

    pub fn getNetworkLogs(self: *Page) ![]const u8 {
        return try std.json.stringifyFromSlice(
            self.browser.allocator,
            self.network_logs.items,
            .{},
        );
    }

    pub fn getConsoleLogs(self: *Page) ![]const u8 {
        return try std.json.stringifyFromSlice(
            self.browser.allocator,
            self.console_logs.items,
            .{},
        );
    }

    pub fn clearLogs(self: *Page) void {
        self.network_logs.clear();
        self.console_logs.clear();
    }

    pub fn screenshot(self: *Page, path: []const u8) !void {
        @compileError("Screenshot not implemented yet. Requires GUI or headless rendering.");
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){ .start_size = 1024 * 1024 };
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Parse command line arguments
    var args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var config = SweefConfig{};

    var i: usize = 1; // Skip program name
    while (i < args.len) : (i += 1) {
        const arg = args[i];

        if (std.mem.eql(u8, arg, "--headless")) {
            config.headless = true;
        } else if (std.mem.eql(u8, arg, "--gui")) {
            config.gui = true;
            config.headless = false;
        } else if (std.mem.eql(u8, arg, "--debug")) {
            config.debug = true;
        } else if (std.mem.eql(u8, arg, "--mcp")) {
            config.mcp = true;
        } else if (std.mem.eql(u8, arg, "--mcp-port") and i + 1 < args.len) {
            config.mcp_port = std.fmt.parseInt(u16, args[i + 1], 10) catch 3000;
            i += 1;
        } else if (std.mem.eql(u8, arg, "--user-agent") and i + 1 < args.len) {
            config.user_agent = args[i + 1];
            i += 1;
        } else if (std.mem.eql(u8, arg, "--viewport") and i + 1 < args.len) {
            const parts = std.mem.split(u8, args[i + 1], "x");
            if (parts.len == 2) {
                config.viewport_width = std.fmt.parseInt(u32, parts[0], 10) catch 800;
                config.viewport_height = std.fmt.parseInt(u32, parts[1], 10) catch 600;
            }
            i += 1;
        } else if (std.mem.eql(u8, arg, "--timeout") and i + 1 < args.len) {
            config.timeout = std.fmt.parseInt(u32, args[i + 1], 10) catch 5000;
            i += 1;
        } else if (std.mem.eql(u8, arg, "--slow-mo") and i + 1 < args.len) {
            config.slow_mo = std.fmt.parseInt(u32, args[i + 1], 10) catch 0;
            i += 1;
        } else if (std.mem.eql(u8, arg, "--disable-js")) {
            config.disable_js = true;
        } else if (std.mem.eql(u8, arg, "--disable-css")) {
            config.disable_css = true;
        } else if (std.mem.eql(u8, arg, "--disable-images")) {
            config.disable_images = true;
        } else if (std.mem.eql(u8, arg, "--script") and i + 1 < args.len) {
            config.script = args[i + 1];
            i += 1;
        } else if (std.mem.eql(u8, arg, "--url") and i + 1 < args.len) {
            config.url = args[i + 1];
            i += 1;
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

    // Initialize and run browser
    const browser = try SweefBrowser.init(config);
    defer browser.deinit();

    try browser.run();
}

fn printUsage() void {
    std.debug.print("Usage: sweef [OPTIONS]\n  --headless    Run in headless mode\n  --gui         Run with GUI\n  --help, -h    Show help\n", .{});
}
