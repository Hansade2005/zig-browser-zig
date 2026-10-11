// Sweef Browser - HTTP Client
// Lightweight HTTP client for the browser core.

const std = @import("std");

pub const HttpMethod = enum {
    GET,
    POST,
    HEAD,
    PUT,
    DELETE,
    PATCH,
    OPTIONS,
};

pub const HttpHeader = struct {
    name: []const u8,
    value: []const u8,
};

pub const HttpHeaders = std.StringHashMap([]const u8);

pub const HttpResponse = struct {
    status: u16,
    status_text: []const u8,
    headers: HttpHeaders,
    body: []const u8,

    pub fn deinit(self: *HttpResponse, allocator: std.mem.Allocator) void {
        self.headers.deinit(allocator);
        allocator.free(self.body);
    }
};

pub const NetworkLog = struct {
    url: []const u8,
    method: []const u8,
    status: u16,
    headers: HttpHeaders,
    body: []const u8,

    pub fn deinit(self: *NetworkLog, allocator: std.mem.Allocator) void {
        self.headers.deinit(allocator);
        allocator.free(self.body);
    }
};

pub const HttpClient = struct {
    allocator: std.mem.Allocator,
    user_agent: []const u8,
    cookies: HttpHeaders,
    timeout: u32,

    pub fn init(allocator: std.mem.Allocator, user_agent: []const u8) !*HttpClient {
        var client = HttpClient{
            .allocator = allocator,
            .user_agent = user_agent,
            .cookies = .{},
            .timeout = 5000,
        };
        return &client;
    }

    pub fn deinit(self: *HttpClient) void {
        self.cookies.deinit(self.allocator);
    }

    pub fn setTimeout(self: *HttpClient, timeout: u32) void {
        self.timeout = timeout;
    }

    pub fn setUserAgent(self: *HttpClient, user_agent: []const u8) void {
        self.user_agent = user_agent;
    }

    pub fn addCookie(self: *HttpClient, name: []const u8, value: []const u8, url: []const u8) !void {
        try self.cookies.put(name, value);
    }

    pub fn getCookie(self: *HttpClient, name: []const u8) ?[]const u8 {
        return self.cookies.get(name);
    }

    pub fn clearCookies(self: *HttpClient) void {
        self.cookies.clear();
    }

    pub fn request(self: *HttpClient, options: struct {
        method: HttpMethod,
        url: []const u8,
        headers: ?HttpHeaders,
        body: ?[]const u8,
    }) !HttpResponse {
        // Parse URL
        const parsed_url = try parseUrl(options.url);
        defer parsed_url.deinit(self.allocator);

        // Build request
        const host = parsed_url.host orelse return error.InvalidUrl;
        const port = parsed_url.port orelse if (std.mem.eql(u8, parsed_url.scheme, "https")) 443 else 80;
        const path = parsed_url.path orelse "/";

        // Create socket
        const socket = try std.net.StreamSocket.init(.IPv4);
        defer socket.deinit();

        const address = try std.net.Address.parseIp(host, port);
        try socket.connect(address, self.timeout);

        // Build HTTP request
        var request_buffer = std.ArrayList(u8).init(self.allocator);
        defer request_buffer.deinit();

        // Request line
        const method_str = switch (options.method) {
            .GET => "GET",
            .POST => "POST",
            .HEAD => "HEAD",
            .PUT => "PUT",
            .DELETE => "DELETE",
            .PATCH => "PATCH",
            .OPTIONS => "OPTIONS",
        };

        try request_buffer.appendSlice(method_str);
        try request_buffer.appendSlice(" ");
        try request_buffer.appendSlice(path);
        try request_buffer.appendSlice(" HTTP/1.1\r\n");

        // Headers
        try request_buffer.appendSlice("Host: ");
        try request_buffer.appendSlice(host);
        if (port != 80 and port != 443) {
            try request_buffer.appendSlice(":");
            try request_buffer.appendSlice(std.fmt.allocPrint(self.allocator, "{d}", .{port}) orelse return error.AllocationFailed);
        }
        try request_buffer.appendSlice("\r\n");

        try request_buffer.appendSlice("User-Agent: ");
        try request_buffer.appendSlice(self.user_agent);
        try request_buffer.appendSlice("\r\n");

        try request_buffer.appendSlice("Connection: close\r\n");

        // Custom headers
        if (options.headers) |headers| {
            var iter = headers.iterator();
            while (iter.next()) |entry| {
                try request_buffer.appendSlice(entry.key_ptr.*);
                try request_buffer.appendSlice(": ");
                try request_buffer.appendSlice(entry.value_ptr.*);
                try request_buffer.appendSlice("\r\n");
            }
        }

        // Cookies
        if (self.cookies.count() > 0) {
            try request_buffer.appendSlice("Cookie: ");
            var first = true;
            var cookie_iter = self.cookies.iterator();
            while (cookie_iter.next()) |entry| {
                if (!first) {
                    try request_buffer.appendSlice("; ");
                }
                try request_buffer.appendSlice(entry.key_ptr.*);
                try request_buffer.appendSlice("=");
                try request_buffer.appendSlice(entry.value_ptr.*);
                first = false;
            }
            try request_buffer.appendSlice("\r\n");
        }

        // Body (for POST, PUT, PATCH)
        if (options.body) |body| {
            try request_buffer.appendSlice("Content-Length: ");
            try request_buffer.appendSlice(std.fmt.allocPrint(self.allocator, "{d}", .{body.len}) orelse return error.AllocationFailed);
            try request_buffer.appendSlice("\r\n");
            try request_buffer.appendSlice("Content-Type: application/x-www-form-urlencoded\r\n");
        }

        try request_buffer.appendSlice("\r\n");

        // Send request
        if (options.body) |body| {
            try request_buffer.appendSlice(body);
        }

        try socket.writer().writeAll(request_buffer.items);

        // Read response
        var response_buffer = std.ArrayList(u8).init(self.allocator);
        defer response_buffer.deinit();

        var reader = socket.reader();
        var temp_buffer: [4096]u8 = undefined;

        // Read headers
        var headers_end = false;
        while (!headers_end) {
            const bytes_read = try reader.read(&temp_buffer);
            if (bytes_read == 0) return error.ConnectionClosed;

            try response_buffer.appendSlice(temp_buffer[0..bytes_read]);

            // Check for end of headers (\r\n\r\n)
            if (response_buffer.items.len >= 4 and
                std.mem.eql(u8, response_buffer.items[response_buffer.items.len - 4 ..], "\r\n\r\n"))
            {
                headers_end = true;
            }
        }

        // Parse status line
        const headers_str = response_buffer.items;
        const first_line_end = std.mem.indexOf(u8, headers_str, "\r\n") orelse return error.InvalidResponse;
        const status_line = headers_str[0..first_line_end];

        const status_parts = std.mem.split(u8, status_line, " ");
        if (status_parts.len < 3) return error.InvalidResponse;

        const status = std.fmt.parseInt(u16, status_parts[1], 10) catch return error.InvalidResponse;
        const status_text = status_parts[2];

        // Parse headers
        var headers = HttpHeaders.init(self.allocator);
        defer headers.deinit(self.allocator);

        const headers_start = first_line_end + 2; // Skip \r\n
        var header_start: usize = headers_start;
        while (header_start < headers_str.len) : (header_start += 1) {
            const header_end = std.mem.indexOf(u8, headers_str[header_start..], "\r\n") orelse break;
            const header_line = headers_str[header_start..header_start + header_end];

            if (header_line.len == 0) break; // End of headers

            const colon_pos = std.mem.indexOf(u8, header_line, ":") orelse continue;
            const name = std.mem.trim(u8, header_line[0..colon_pos], " ");
            const value = std.mem.trim(u8, header_line[colon_pos + 1 ..], " ");

            _ = try headers.put(self.allocator.dupe(u8, name), self.allocator.dupe(u8, value));

            header_start += header_end + 2; // Skip \r\n
        }

        // Check for chunked encoding
        const transfer_encoding = headers.get("Transfer-Encoding");
        const content_length = headers.get("Content-Length");

        var body_buffer = std.ArrayList(u8).init(self.allocator);
        defer body_buffer.deinit();

        if (transfer_encoding) |encoding| {
            if (std.mem.eql(u8, encoding, "chunked")) {
                // Read chunked body
                var chunked = true;
                while (chunked) {
                    const bytes_read = try reader.read(&temp_buffer);
                    if (bytes_read == 0) break;
                    try body_buffer.appendSlice(temp_buffer[0..bytes_read]);

                    // Check for end of chunk (0\r\n\r\n)
                    if (body_buffer.items.len >= 5 and
                        std.mem.eql(u8, body_buffer.items[body_buffer.items.len - 5 ..], "0\r\n\r\n"))
                    {
                        // Remove trailing chunk metadata
                        const end_pos = std.mem.indexOf(u8, body_buffer.items, "0\r\n\r\n") orelse continue;
                        body_buffer.items = body_buffer.items[0..end_pos];
                        chunked = false;
                    }
                }
            }
        } else if (content_length) |length_str| {
            const length = std.fmt.parseInt(usize, length_str, 10) catch return error.InvalidContentLength;
            var remaining = length;

            while (remaining > 0) {
                const bytes_to_read = @min(remaining, temp_buffer.len);
                const bytes_read = try reader.read(&temp_buffer[0..bytes_to_read]);
                if (bytes_read == 0) return error.ConnectionClosed;
                try body_buffer.appendSlice(temp_buffer[0..bytes_read]);
                remaining -= bytes_read;
            }
        } else {
            // Read until connection closed
            while (true) {
                const bytes_read = try reader.read(&temp_buffer);
                if (bytes_read == 0) break;
                try body_buffer.appendSlice(temp_buffer[0..bytes_read]);
            }
        }

        // Build response
        var response = HttpResponse{
            .status = status,
            .status_text = self.allocator.dupe(u8, status_text),
            .headers = .{},
            .body = self.allocator.dupe(u8, body_buffer.items),
        };

        // Copy headers to response
        var iter = headers.iterator();
        while (iter.next()) |entry| {
            _ = try response.headers.put(
                self.allocator.dupe(u8, entry.key_ptr.*),
                self.allocator.dupe(u8, entry.value_ptr.*),
            );
        }

        return response;
    }

    pub fn get(self: *HttpClient, url: []const u8) !HttpResponse {
        return self.request(.{
            .method = .GET,
            .url = url,
            .headers = null,
            .body = null,
        });
    }

    pub fn post(self: *HttpClient, url: []const u8, body: []const u8, headers: ?HttpHeaders) !HttpResponse {
        return self.request(.{
            .method = .POST,
            .url = url,
            .headers = headers,
            .body = body,
        });
    }

    pub fn head(self: *HttpClient, url: []const u8) !HttpResponse {
        return self.request(.{
            .method = .HEAD,
            .url = url,
            .headers = null,
            .body = null,
        });
    }
};

// URL parsing
const ParsedUrl = struct {
    scheme: []const u8,
    host: ?[]const u8,
    port: ?u16,
    path: ?[]const u8,
    query: ?[]const u8,
    fragment: ?[]const u8,

    pub fn deinit(self: *ParsedUrl, allocator: std.mem.Allocator) void {
        if (self.host) |h| allocator.free(h);
        if (self.path) |p| allocator.free(p);
        if (self.query) |q| allocator.free(q);
        if (self.fragment) |f| allocator.free(f);
    }
};

fn parseUrl(allocator: std.mem.Allocator, url: []const u8) !ParsedUrl {
    var parsed = ParsedUrl{
        .scheme = "http",
        .host = null,
        .port = null,
        .path = null,
        .query = null,
        .fragment = null,
    };

    // Check for scheme
    const scheme_end = std.mem.indexOf(u8, url, "://") orelse return parsed;
    parsed.scheme = url[0..scheme_end];

    const after_scheme = scheme_end + 3;

    // Find path/query/fragment
    const path_start = std.mem.indexOf(u8, url[after_scheme..], "/") orelse url.len;
    const host_part = url[after_scheme..after_scheme + path_start];

    // Parse host and port
    const port_pos = std.mem.indexOf(u8, host_part, ":") orelse null;
    if (port_pos) |pos| {
        parsed.host = try allocator.dupe(u8, host_part[0..pos]);
        const port_str = host_part[pos + 1 ..];
        parsed.port = std.fmt.parseInt(u16, port_str, 10) catch null;
    } else {
        parsed.host = try allocator.dupe(u8, host_part);
    }

    // Parse path
    if (path_start < url.len) {
        const path_end = std.mem.indexOf(u8, url[after_scheme + path_start..], "?") orelse
            std.mem.indexOf(u8, url[after_scheme + path_start..], "#") orelse url.len - (after_scheme + path_start);
        parsed.path = try allocator.dupe(u8, url[after_scheme + path_start .. after_scheme + path_start + path_end]);

        // Parse query
        if (path_start + path_end < url.len and url[after_scheme + path_start + path_end] == '?') {
            const query_start = after_scheme + path_start + path_end + 1;
            const query_end = std.mem.indexOf(u8, url[query_start..], "#") orelse url.len - query_start;
            parsed.query = try allocator.dupe(u8, url[query_start .. query_start + query_end]);

            // Parse fragment
            if (query_start + query_end < url.len and url[query_start + query_end] == '#') {
                parsed.fragment = try allocator.dupe(u8, url[query_start + query_end + 1 ..]);
            }
        } else if (path_start + path_end < url.len and url[after_scheme + path_start + path_end] == '#') {
            parsed.fragment = try allocator.dupe(u8, url[after_scheme + path_start + path_end + 1 ..]);
        }
    }

    return parsed;
}
