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

        if (config.mcp) {
            browser.mcp_server = try mcp.MCPServer.init(&browser, config.mcp_port);
        }

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
        for (self.pages.items, 0..) |p, i| {
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
        if (self.config.script) |script_path| {
            try self.runScript(script_path);
            return;
        }

        if (self.config.url) |url| {
            const page = try self.newPage();
            try page.goto(url);
            return;
        }

        if (self.config.repl) {
            try self.runREPL();
            return;
        }

        if (self.config.mcp) {
            if (self.mcp_server) |server| {
                try server.run();
            }
            return;
        }

        // Default: open about:blank
        const page = try self.newPage();
        try page.goto("about:blank");
    }

    pub fn runScript(self: *SweefBrowser, path: []const u8) !void {
        const page = try self.newPage();
        const script = try std.fs.cwd().readFileAlloc(self.allocator, path, 1024 * 1024);
        defer self.allocator.free(script);

        try page.evaluate(script);

        // Wait for script to complete
        std.time.sleep(1000 * 1000 * 1000); // 1 second
    }

    pub fn runREPL(self: *SweefBrowser) !void {
        const page = try self.newPage();

        std.debug.print("Sweef REPL Mode\n", .{});
        std.debug.print("Type JavaScript code and press Enter. Type 'exit' to quit.\n", .{});

        while (true) {
            std.debug.print("> ", .{});
            const line = std.io.getStdIn().readUntilDelimiterOrEofAlloc(self.allocator, '\n', 1024) catch continue;
            defer self.allocator.free(line);

            const trimmed = std.mem.trim(u8, line, " \r\n");
            if (std.mem.eql(u8, trimmed, "exit")) {
                break;
            }

            try page.evaluate(trimmed);
        }
    }
};

const Page = struct {
    browser: *SweefBrowser,
    config: SweefConfig,
    allocator: std.mem.Allocator,
    url: ?[]const u8,
    html: ?[]const u8,
    dom: ?*dom.DOMNode,
    js_context: ?*js.JSContext,

    pub fn init(browser: *SweefBrowser, config: SweefConfig) !*Page {
        return .{
            .browser = browser,
            .config = config,
            .allocator = std.heap.page_allocator,
            .url = null,
            .html = null,
            .dom = null,
            .js_context = if (!config.disable_js) js.JSEngine.createContext() else null,
        };
    }

    pub fn deinit(self: *Page) void {
        if (self.js_context) |ctx| {
            ctx.deinit();
        }
        if (self.dom) |d| {
            d.deinit();
        }
        self.allocator = undefined;
    }

    pub fn goto(self: *Page, url: []const u8) !void {
        _ = url;
        // HTTP request would go here
        if (self.config.debug) {
            std.debug.print("Loading: {s}\n", .{url});
        }
    }

    pub fn evaluate(self: *Page, script: []const u8) !void {
        _ = script;
        if (self.config.debug) {
            std.debug.print("Evaluating: {s}\n", .{script});
        }
    }
};

fn parseArgs() SweefConfig {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){ .start_size = 1024 * 1024 };
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var args = std.process.args();

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

    return config;
}

fn printUsage() void {
    std.debug.print("Usage: sweef [OPTIONS]\n  --headless    Run in headless mode\n  --gui         Run with GUI\n  --help, -h    Show help\n", .{});
}

pub fn main() !void {
    const config = parseArgs();

    const browser = try SweefBrowser.init(config);
    defer browser.deinit();

    try browser.run();
}
