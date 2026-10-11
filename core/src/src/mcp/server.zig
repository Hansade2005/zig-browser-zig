// Sweef Browser - MCP Server
// Model Context Protocol server for AI agent integration.

const std = @import("std");
const json = std.json;
const http = @import("http");
const dom = @import("dom");

pub const MCPServer = struct {
    browser: *anyopaque, // Reference to SweefBrowser
    port: u16,
    allocator: std.mem.Allocator,
    running: bool,
    server_socket: ?std.net.StreamServer,

    pub fn init(browser: *anyopaque, port: u16) !*MCPServer {
        return &MCPServer{
            .browser = browser,
            .port = port,
            .allocator = std.heap.page_allocator,
            .running = false,
            .server_socket = null,
        };
    }

    pub fn deinit(self: *MCPServer) void {
        if (self.server_socket) |socket| {
            socket.deinit();
        }
        self.running = false;
    }

    pub fn run(self: *MCPServer) !void {
        self.running = true;

        // Create server socket
        const address = try std.net.Address.parseIp("0.0.0.0", self.port);
        const server = try std.net.StreamServer.init(.IPv4);
        self.server_socket = server;

        try server.listen(address);

        std.debug.print("MCP Server listening on port {d}\n", .{self.port});

        while (self.running) {
            const connection = try server.accept();
            
            // Handle connection in a new thread
            try std.Thread.spawn(.{}, &handleConnection, .{ self, connection });
        }
    }

    fn handleConnection(self: *MCPServer, connection: std.net.StreamConnection) !void {
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

    fn handleRequest(self: *MCPServer, root: json.Value) !json.StringBuilder {
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
        self: *MCPServer,
        method: []const u8,
        params: ?json.Value,
        browser: *anyopaque,
    ) !json.Value {
        // Browser methods
        if (std.mem.eql(u8, method, "browser.new_page")) {
            return try self.handleNewPage(params, browser);
        }
        if (std.mem.eql(u8, method, "browser.pages")) {
            return try self.handlePages(params, browser);
        }
        if (std.mem.eql(u8, method, "browser.close_page")) {
            return try self.handleClosePage(params, browser);
        }
        if (std.mem.eql(u8, method, "browser.close")) {
            return try self.handleClose(browser);
        }
        if (std.mem.eql(u8, method, "browser.version")) {
            return try self.handleVersion();
        }
        if (std.mem.eql(u8, method, "browser.set_user_agent")) {
            return try self.handleSetUserAgent(params, browser);
        }
        if (std.mem.eql(u8, method, "browser.set_viewport")) {
            return try self.handleSetViewport(params, browser);
        }
        if (std.mem.eql(u8, method, "browser.set_offline")) {
            return try self.handleSetOffline(params, browser);
        }
        if (std.mem.eql(u8, method, "browser.set_geolocation")) {
            return try self.handleSetGeolocation(params, browser);
        }
        if (std.mem.eql(u8, method, "browser.add_cookies")) {
            return try self.handleAddCookies(params, browser);
        }
        if (std.mem.eql(u8, method, "browser.get_cookies")) {
            return try self.handleGetCookies(params, browser);
        }
        if (std.mem.eql(u8, method, "browser.clear_cookies")) {
            return try self.handleClearCookies(browser);
        }

        // Page methods
        if (std.mem.startsWith(u8, method, "page.")) {
            return try self.handlePageMethod(method, params, browser);
        }

        return error.UnknownMethod;
    }

    // Browser method handlers
    fn handleNewPage(self: *MCPServer, params: ?json.Value, browser: *anyopaque) !json.Value {
        _ = params; // For now, ignore params
        
        // Call browser.newPage()
        // This is a placeholder - in reality, we'd call the actual method
        // For now, return a mock page ID
        return json.Value{
            .kind = .object,
            .object = .{
                .pageId = 1,
            },
        };
    }

    fn handlePages(self: *MCPServer, params: ?json.Value, browser: *anyopaque) !json.Value {
        _ = params;
        _ = browser;
        
        return json.Value{
            .kind = .array,
            .array = &.{
                .{
                    .kind = .object,
                    .object = .{
                        .pageId = 1,
                        .url = "about:blank",
                        .title = "",
                    },
                },
            },
        };
    }

    fn handleClosePage(self: *MCPServer, params: ?json.Value, browser: *anyopaque) !json.Value {
        _ = browser;
        
        const page_id = params.?.object.get("pageId") orelse return error.MissingPageId;
        
        return json.Value{
            .kind = .object,
            .object = .{
                .success = true,
            },
        };
    }

    fn handleClose(self: *MCPServer, browser: *anyopaque) !json.Value {
        _ = browser;
        self.running = false;
        
        return json.Value{
            .kind = .object,
            .object = .{
                .success = true,
            },
        };
    }

    fn handleVersion(self: *MCPServer) !json.Value {
        return json.Value{
            .kind = .object,
            .object = .{
                .version = "0.1.0",
                .userAgent = "Sweef/0.1.0",
            },
        };
    }

    fn handleSetUserAgent(self: *MCPServer, params: ?json.Value, browser: *anyopaque) !json.Value {
        _ = browser;
        
        const user_agent = params.?.object.get("userAgent") orelse return error.MissingUserAgent;
        
        return json.Value{
            .kind = .object,
            .object = .{
                .success = true,
            },
        };
    }

    fn handleSetViewport(self: *MCPServer, params: ?json.Value, browser: *anyopaque) !json.Value {
        _ = browser;
        
        const width = params.?.object.get("width") orelse return error.MissingWidth;
        const height = params.?.object.get("height") orelse return error.MissingHeight;
        
        return json.Value{
            .kind = .object,
            .object = .{
                .success = true,
            },
        };
    }

    fn handleSetOffline(self: *MCPServer, params: ?json.Value, browser: *anyopaque) !json.Value {
        _ = browser;
        
        const offline = params.?.object.get("offline") orelse return error.MissingOffline;
        
        return json.Value{
            .kind = .object,
            .object = .{
                .success = true,
            },
        };
    }

    fn handleSetGeolocation(self: *MCPServer, params: ?json.Value, browser: *anyopaque) !json.Value {
        _ = browser;
        
        const latitude = params.?.object.get("latitude") orelse return error.MissingLatitude;
        const longitude = params.?.object.get("longitude") orelse return error.MissingLongitude;
        
        return json.Value{
            .kind = .object,
            .object = .{
                .success = true,
            },
        };
    }

    fn handleAddCookies(self: *MCPServer, params: ?json.Value, browser: *anyopaque) !json.Value {
        _ = browser;
        
        const cookies = params.?.object.get("cookies") orelse return error.MissingCookies;
        
        return json.Value{
            .kind = .object,
            .object = .{
                .success = true,
            },
        };
    }

    fn handleGetCookies(self: *MCPServer, params: ?json.Value, browser: *anyopaque) !json.Value {
        _ = browser;
        _ = params;
        
        return json.Value{
            .kind = .array,
            .array = &.{},
        };
    }

    fn handleClearCookies(self: *MCPServer, browser: *anyopaque) !json.Value {
        _ = browser;
        
        return json.Value{
            .kind = .object,
            .object = .{
                .success = true,
            },
        };
    }

    // Page method handlers
    fn handlePageMethod(
        self: *MCPServer,
        method: []const u8,
        params: ?json.Value,
        browser: *anyopaque,
    ) !json.Value {
        const page_id = params.?.object.get("pageId") orelse return error.MissingPageId;

        const action = method[5..]; // Remove "page." prefix

        // Page navigation methods
        if (std.mem.eql(u8, action, "goto")) {
            return try self.handlePageGoto(params, browser);
        }
        if (std.mem.eql(u8, action, "reload")) {
            return try self.handlePageReload(params, browser);
        }
        if (std.mem.eql(u8, action, "go_back")) {
            return try self.handlePageGoBack(params, browser);
        }
        if (std.mem.eql(u8, action, "go_forward")) {
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
        if (std.mem.eql(u8, action, "set_content")) {
            return try self.handlePageSetContent(params, browser);
        }

        // Page action methods
        if (std.mem.eql(u8, action, "click")) {
            return try self.handlePageClick(params, browser);
        }
        if (std.mem.eql(u8, action, "dblclick")) {
            return try self.handlePageDblClick(params, browser);
        }
        if (std.mem.eql(u8, action, "hover")) {
            return try self.handlePageHover(params, browser);
        }
        if (std.mem.eql(u8, action, "focus")) {
            return try self.handlePageFocus(params, browser);
        }
        if (std.mem.eql(u8, action, "type")) {
            return try self.handlePageType(params, browser);
        }
        if (std.mem.eql(u8, action, "fill")) {
            return try self.handlePageFill(params, browser);
        }
        if (std.mem.eql(u8, action, "select")) {
            return try self.handlePageSelect(params, browser);
        }
        if (std.mem.eql(u8, action, "check")) {
            return try self.handlePageCheck(params, browser);
        }
        if (std.mem.eql(u8, action, "uncheck")) {
            return try self.handlePageUncheck(params, browser);
        }
        if (std.mem.eql(u8, action, "press")) {
            return try self.handlePagePress(params, browser);
        }
        if (std.mem.eql(u8, action, "set_input_files")) {
            return try self.handlePageSetInputFiles(params, browser);
        }

        // Page wait methods
        if (std.mem.eql(u8, action, "wait_for_selector")) {
            return try self.handlePageWaitForSelector(params, browser);
        }
        if (std.mem.eql(u8, action, "wait_for_function")) {
            return try self.handlePageWaitForFunction(params, browser);
        }
        if (std.mem.eql(u8, action, "wait_for_navigation")) {
            return try self.handlePageWaitForNavigation(params, browser);
        }
        if (std.mem.eql(u8, action, "wait_for_load_state")) {
            return try self.handlePageWaitForLoadState(params, browser);
        }
        if (std.mem.eql(u8, action, "wait_for_request")) {
            return try self.handlePageWaitForRequest(params, browser);
        }
        if (std.mem.eql(u8, action, "wait_for_response")) {
            return try self.handlePageWaitForResponse(params, browser);
        }
        if (std.mem.eql(u8, action, "wait_for_timeout")) {
            return try self.handlePageWaitForTimeout(params, browser);
        }

        // Page evaluation methods
        if (std.mem.eql(u8, action, "evaluate")) {
            return try self.handlePageEvaluate(params, browser);
        }
        if (std.mem.eql(u8, action, "evaluate_handle")) {
            return try self.handlePageEvaluateHandle(params, browser);
        }

        // Page DOM methods
        if (std.mem.eql(u8, action, "get_dom")) {
            return try self.handlePageGetDom(params, browser);
        }
        if (std.mem.eql(u8, action, "query_selector")) {
            return try self.handlePageQuerySelector(params, browser);
        }
        if (std.mem.eql(u8, action, "query_selector_all")) {
            return try self.handlePageQuerySelectorAll(params, browser);
        }
        if (std.mem.eql(u8, action, "text_content")) {
            return try self.handlePageTextContent(params, browser);
        }
        if (std.mem.eql(u8, action, "inner_html")) {
            return try self.handlePageInnerHtml(params, browser);
        }
        if (std.mem.eql(u8, action, "inner_text")) {
            return try self.handlePageInnerText(params, browser);
        }
        if (std.mem.eql(u8, action, "get_attribute")) {
            return try self.handlePageGetAttribute(params, browser);
        }
        if (std.mem.eql(u8, action, "get_bounding_box")) {
            return try self.handlePageGetBoundingBox(params, browser);
        }
        if (std.mem.eql(u8, action, "get_computed_style")) {
            return try self.handlePageGetComputedStyle(params, browser);
        }
        if (std.mem.eql(u8, action, "is_visible")) {
            return try self.handlePageIsVisible(params, browser);
        }
        if (std.mem.eql(u8, action, "is_hidden")) {
            return try self.handlePageIsHidden(params, browser);
        }
        if (std.mem.eql(u8, action, "is_enabled")) {
            return try self.handlePageIsEnabled(params, browser);
        }
        if (std.mem.eql(u8, action, "is_checked")) {
            return try self.handlePageIsChecked(params, browser);
        }
        if (std.mem.eql(u8, action, "is_selected")) {
            return try self.handlePageIsSelected(params, browser);
        }

        // Page network methods
        if (std.mem.eql(u8, action, "get_network_logs")) {
            return try self.handlePageGetNetworkLogs(params, browser);
        }
        if (std.mem.eql(u8, action, "clear_network_logs")) {
            return try self.handlePageClearNetworkLogs(params, browser);
        }
        if (std.mem.eql(u8, action, "set_request_interception")) {
            return try self.handlePageSetRequestInterception(params, browser);
        }

        // Page console methods
        if (std.mem.eql(u8, action, "get_console_logs")) {
            return try self.handlePageGetConsoleLogs(params, browser);
        }
        if (std.mem.eql(u8, action, "clear_console_logs")) {
            return try self.handlePageClearConsoleLogs(params, browser);
        }

        // Page screenshot method
        if (std.mem.eql(u8, action, "screenshot")) {
            return try self.handlePageScreenshot(params, browser);
        }

        return error.UnknownMethod;
    }

    // Placeholder handlers for page methods
    fn handlePageGoto(self: *MCPServer, params: ?json.Value, browser: *anyopaque) !json.Value {
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

    fn handlePageEvaluate(self: *MCPServer, params: ?json.Value, browser: *anyopaque) !json.Value {
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

    fn handlePageGetDom(self: *MCPServer, params: ?json.Value, browser: *anyopaque) !json.Value {
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

    // ... Other page method handlers would go here

    // Error handling
    fn createErrorResponse(self: *MCPServer, root: json.Value, err: anyerror) !json.StringBuilder {
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
pub const MCPServerError = error{
    MissingMethod,
    MissingPageId,
    MissingUrl,
    MissingJs,
    MissingUserAgent,
    MissingWidth,
    MissingHeight,
    MissingOffline,
    MissingLatitude,
    MissingLongitude,
    MissingCookies,
    UnknownMethod,
};
