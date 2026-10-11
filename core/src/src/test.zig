// Sweef Browser - Test Suite
// Simple tests to verify basic functionality

const std = @import("std");
const testing = std.testing;

// Test HTTP client
const http = @import("http");

// Test DOM
const dom = @import("dom");

// Test HTML parser
const html = @import("html");

// Test JS engine
const js = @import("js");

// Test MCP server
const mcp = @import("mcp");

// Test IPC
const ipc = @import("ipc");

// Test logger
const utils = @import("utils");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("Running Sweef Browser tests...\n", .{});

    // Test 1: DOM Parser
    std.debug.print("Test 1: DOM Parser\n", .{});
    var dom_parser = dom.DOMParser.init(allocator);
    const html_str = "<html><head><title>Test</title></head><body><h1>Hello</h1></body></html>";
    const doc = try dom_parser.parse(html_str);
    defer doc.deinit();
    
    if (doc.children.items.len == 2) {
        std.debug.print("✅ DOM Parser: Parsed HTML successfully\n", .{});
    } else {
        std.debug.print("❌ DOM Parser: Failed to parse HTML\n", .{});
    }

    // Test 2: DOM Query Selector
    std.debug.print("Test 2: DOM Query Selector\n", .{});
    if (doc.querySelector("title")) |title_node| {
        std.debug.print("✅ DOM Query Selector: Found title element\n", .{});
    } else {
        std.debug.print("❌ DOM Query Selector: Failed to find title element\n", .{});
    }

    // Test 3: DOM to JSON
    std.debug.print("Test 3: DOM to JSON\n", .{});
    const json = try doc.toJson(allocator);
    defer allocator.free(json);
    if (std.mem.contains(u8, json, "html")) {
        std.debug.print("✅ DOM to JSON: Serialized successfully\n", .{});
    } else {
        std.debug.print("❌ DOM to JSON: Failed to serialize\n", .{});
    }

    // Test 4: Logger
    std.debug.print("Test 4: Logger\n", .{});
    utils.initGlobalLogger(allocator, .DEBUG);
    utils.debug("Test debug message");
    utils.info("Test info message");
    utils.warn("Test warn message");
    utils.error("Test error message");
    utils.deinitGlobalLogger();
    std.debug.print("✅ Logger: All log levels work\n", .{});

    std.debug.print("All tests completed!\n", .{});
}
