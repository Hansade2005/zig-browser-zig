// Sweef Browser - IPC Server
// Inter-process communication for SDK integration.

const std = @import("std");
const json = std.json;

pub const IPCServer = struct {
    browser: *anyopaque, // Reference to SweefBrowser
    allocator: std.mem.Allocator,
    running: bool,
    server_socket: ?std.net.StreamServer,
    port: u16 = 9222, // Default port for IPC

    pub fn init(browser: *anyopaque) !*IPCServer {
        return &IPCServer{
            .browser = browser,
            .allocator = std.heap.page_allocator,
            .running = false,
            .server_socket = null,
        };
    }

    pub fn deinit(self: *IPCServer) void {
        if (self.server_socket) |socket| {
            socket.deinit();
        }
        self.running = false;
    }

    pub fn run(self: *IPCServer) !void {
        self.running = true;

        // Create server socket
        const address = try std.net.Address.parseIp("127.0.0.1", self.port);
        const server = try std.net.StreamServer.init(.IPv4);
        self.server_socket = server;

        try server.listen(address);

        std.debug.print("IPC Server listening on port {d}\n", .{self.port});

        while (self.running) {
            const connection = try server.accept();
            
            // Handle connection in a new thread
            try std.Thread.spawn(.{}, &handleConnection, .{ self, connection });
        }
    }

    fn handleConnection(self: *IPCServer, connection: std.net.StreamConnection) !void {
        defer connection.stream.deinit();

        const reader = connection.stream.reader();
        const writer = connection.stream.writer();

        var buffer: [4096]u8 = undefined;

        while (true) {
            const bytes_read = try reader.read(&buffer);
            if (bytes_read == 0) {
                break; // Connection closed
            }

            const request = buffer[0..bytes_read];

            // Parse JSON-RPC request
            var parsed = json.parseFromSlice([]const u8, request, .{}) catch |err| {
                try writer.print("Invalid JSON: {s}\n", .{@errorName(err)});
                try writer.flush();
                continue;
            };
            defer parsed.deinit();

            // Handle request
            const response = self.handleRequest(parsed.root) catch |err| {
                try self.createErrorResponse(parsed.root, err);
            };
            defer response.deinit();

            // Send response
            try writer.writeAll(response.buffer);
            try writer.flush();
        }
    }

    fn handleRequest(self: *IPCServer, root: json.Value) !json.StringBuilder {
        const browser = @ptrCast([*]anyopaque, self.browser);

        const method = root.object.get("method") orelse return self.createErrorResponse(
            root,
            error.MissingMethod,
        );

        const params = root.object.get("params");
        const id = root.object.get("id");

        // Dispatch to appropriate handler
        const result = try self.dispatchMethod(method, params, browser);

        // Create success response
        var response = json.StringBuilder.init(self.allocator);
        response.objectBegin();
        
        if (id) |id_val| {
            response.objectField("id");
            json.stringify(response, id_val);
        }
        
        response.objectField("result");
        json.stringify(response, result);
        
        response.objectEnd();

        return response;
    }

    fn dispatchMethod(
        self: *IPCServer,
        method: []const u8,
        params: ?json.Value,
        browser: *anyopaque,
    ) !json.Value {
        // For now, delegate to MCP server handlers
        // In a real implementation, we'd have separate IPC handlers
        
        // Browser methods
        if (std.mem.eql(u8, method, "Browser.launch")) {
            return try self.handleBrowserLaunch(params);
        }
        if (std.mem.eql(u8, method, "Browser.connect")) {
            return try self.handleBrowserConnect(params);
        }
        if (std.mem.eql(u8, method, "Browser.newContext")) {
            return try self.handleBrowserNewContext(params, browser);
        }
        if (std.mem.eql(u8, method, "Browser.contexts")) {
            return try self.handleBrowserContexts(params, browser);
        }
        if (std.mem.eql(u8, method, "Browser.close")) {
            return try self.handleBrowserClose(browser);
        }
        if (std.mem.eql(u8, method, "Browser.version")) {
            return try self.handleBrowserVersion();
        }

        // BrowserContext methods
        if (std.mem.startsWith(u8, method, "BrowserContext.")) {
            return try self.handleBrowserContextMethod(method, params, browser);
        }

        // Page methods
        if (std.mem.startsWith(u8, method, "Page.")) {
            return try self.handlePageMethod(method, params, browser);
        }

        return error.UnknownMethod;
    }

    // Browser method handlers
    fn handleBrowserLaunch(self: *IPCServer, params: ?json.Value) !json.Value {
        _ = params;
        
        return json.Value{
            .kind = .object,
            .object = .{
                .browser = json.Value{
                    .kind = .object,
                    .object = .{},
                },
            },
        };
    }

    fn handleBrowserConnect(self: *IPCServer, params: ?json.Value) !json.Value {
        _ = params;
        
        return json.Value{
            .kind = .object,
            .object = .{
                .browser = json.Value{
                    .kind = .object,
                    .object = .{},
                },
            },
        };
    }

    fn handleBrowserNewContext(self: *IPCServer, params: ?json.Value, browser: *anyopaque) !json.Value {
        _ = params;
        _ = browser;
        
        return json.Value{
            .kind = .object,
            .object = .{
                .context = json.Value{
                    .kind = .object,
                    .object = .{},
                },
            },
        };
    }

    fn handleBrowserContexts(self: *IPCServer, params: ?json.Value, browser: *anyopaque) !json.Value {
        _ = params;
        _ = browser;
        
        return json.Value{
            .kind = .array,
            .array = &.{
                json.Value{
                    .kind = .object,
                    .object = .{},
                },
            },
        };
    }

    fn handleBrowserClose(self: *IPCServer, browser: *anyopaque) !json.Value {
        _ = browser;
        self.running = false;
        
        return json.Value{
            .kind = .object,
            .object = .{},
        };
    }

    fn handleBrowserVersion(self: *IPCServer) !json.Value {
        return json.Value{
            .kind = .object,
            .object = .{
                .version = "0.1.0",
            },
        };
    }

    // BrowserContext method handlers
    fn handleBrowserContextMethod(
        self: *IPCServer,
        method: []const u8,
        params: ?json.Value,
        browser: *anyopaque,
    ) !json.Value {
        const action = method["BrowserContext.".len..];

        if (std.mem.eql(u8, action, "newPage")) {
            return try self.handleContextNewPage(params, browser);
        }
        if (std.mem.eql(u8, action, "pages")) {
            return try self.handleContextPages(params, browser);
        }
        if (std.mem.eql(u8, action, "close")) {
            return try self.handleContextClose(params, browser);
        }
        if (std.mem.eql(u8, action, "addCookies")) {
            return try self.handleContextAddCookies(params, browser);
        }
        if (std.mem.eql(u8, action, "cookies")) {
            return try self.handleContextCookies(params, browser);
        }
        if (std.mem.eql(u8, action, "clearCookies")) {
            return try self.handleContextClearCookies(params, browser);
        }

        return error.UnknownMethod;
    }

    // Page method handlers
    fn handlePageMethod(
        self: *IPCServer,
        method: []const u8,
        params: ?json.Value,
        browser: *anyopaque,
    ) !json.Value {
        const action = method["Page.".len..];

        // Page navigation methods
        if (std.mem.eql(u8, action, "goto")) {
            return try self.handlePageGoto(params, browser);
        }
        if (std.mem.eql(u8, action, "reload")) {
            return try self.handlePageReload(params, browser);
        }
        if (std.mem.eql(u8, action, "goBack")) {
            return try self.handlePageGoBack(params, browser);
        }
        if (std.mem.eql(u8, action, "goForward")) {
            return try self.handlePageGoForward(params, browser);
        }
        if (std.mem.eql(u8, action, "close")) {
            return try self.handlePageClose(params, browser);
        }

        // Page content methods
        if (std.mem.eql(u8, action, "title")) {
            return try self.handlePageTitle(params, browser);
        }
        if (std.mem.eql(u8, action, "url")) {
            return try self.handlePageUrl(params, browser);
        }
        if (std.mem.eql(u8, action, "content")) {
            return try self.handlePageContent(params, browser);
        }
        if (std.mem.eql(u8, action, "setContent")) {
            return try self.handlePageSetContent(params, browser);
        }

        // Page action methods
        if (std.mem.eql(u8, action, "click")) {
            return try self.handlePageClick(params, browser);
        }
        if (std.mem.eql(u8, action, "type")) {
            return try self.handlePageType(params, browser);
        }
        if (std.mem.eql(u8, action, "fill")) {
            return try self.handlePageFill(params, browser);
        }

        // Page wait methods
        if (std.mem.eql(u8, action, "waitForSelector")) {
            return try self.handlePageWaitForSelector(params, browser);
        }

        // Page evaluation methods
        if (std.mem.eql(u8, action, "evaluate")) {
            return try self.handlePageEvaluate(params, browser);
        }

        // Page DOM methods
        if (std.mem.eql(u8, action, "querySelector")) {
            return try self.handlePageQuerySelector(params, browser);
        }
        if (std.mem.eql(u8, action, "getDom")) {
            return try self.handlePageGetDom(params, browser);
        }

        return error.UnknownMethod;
    }

    // Placeholder handlers for context methods
    fn handleContextNewPage(self: *IPCServer, params: ?json.Value, browser: *anyopaque) !json.Value {
        _ = params;
        _ = browser;
        
        return json.Value{
            .kind = .object,
            .object = .{
                .page = json.Value{
                    .kind = .object,
                    .object = .{},
                },
            },
        };
    }

    fn handleContextPages(self: *IPCServer, params: ?json.Value, browser: *anyopaque) !json.Value {
        _ = params;
        _ = browser;
        
        return json.Value{
            .kind = .array,
            .array = &.{
                json.Value{
                    .kind = .object,
                    .object = .{},
                },
            },
        };
    }

    // Placeholder handlers for page methods
    fn handlePageGoto(self: *IPCServer, params: ?json.Value, browser: *anyopaque) !json.Value {
        _ = browser;
        
        const url = params.?.object.get("url") orelse return error.MissingUrl;
        
        return json.Value{
            .kind = .object,
            .object = .{
                .success = true,
                .url = url,
                .status = 200,
            },
        };
    }

    fn handlePageEvaluate(self: *IPCServer, params: ?json.Value, browser: *anyopaque) !json.Value {
        _ = browser;
        
        const js = params.?.object.get("js") orelse return error.MissingJs;
        
        // In a real implementation, we'd evaluate the JS
        // For now, return a mock result
        return json.Value{
            .kind = .object,
            .object = .{
                .result = json.Value{
                    .kind = .null,
                },
            },
        };
    }

    fn handlePageGetDom(self: *IPCServer, params: ?json.Value, browser: *anyopaque) !json.Value {
        _ = browser;
        _ = params;
        
        // Return a mock DOM
        return json.Value{
            .kind = .object,
            .object = .{
                .tagName = "html",
                .children = &.{
                    .{
                        .kind = .object,
                        .object = .{
                            .tagName = "head",
                            .children = &.{},
                        },
                    },
                    .{
                        .kind = .object,
                        .object = .{
                            .tagName = "body",
                            .children = &.{},
                        },
                    },
                },
            },
        };
    }

    // Error handling
    fn createErrorResponse(self: *IPCServer, root: json.Value, err: anyerror) !json.StringBuilder {
        var response = json.StringBuilder.init(self.allocator);
        
        const id = root.object.get("id");

        response.objectBegin();
        
        if (id) |id_val| {
            response.objectField("id");
            json.stringify(response, id_val);
        }
        
        response.objectField("error");
        response.objectBegin();
        response.objectField("code");
        response.number(@intFromError(err));
        response.objectField("message");
        response.string(@errorName(err));
        response.objectEnd();
        
        response.objectEnd();

        return response;
    }
};

// Error types
pub const IPCServerError = error{
    MissingMethod,
    MissingUrl,
    MissingJs,
    UnknownMethod,
};
