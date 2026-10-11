// Sweef Browser - DOM Tree
// Lightweight DOM implementation for the browser core.

const std = @import("std");

pub const DOMNodeType = enum {
    ELEMENT,
    TEXT,
    COMMENT,
    DOCUMENT,
};

pub const DOMNode = struct {
    allocator: std.mem.Allocator,
    node_type: DOMNodeType,
    tag_name: ?[]const u8,
    text_content: ?[]const u8,
    attributes: std.StringHashMap([]const u8),
    children: std.ArrayList(*DOMNode),
    parent: ?*DOMNode,

    pub fn init(allocator: std.mem.Allocator, node_type: DOMNodeType) !DOMNode {
        return DOMNode{
            .allocator = allocator,
            .node_type = node_type,
            .tag_name = null,
            .text_content = null,
            .attributes = .{},
            .children = .{},
            .parent = null,
        };
    }

    pub fn deinit(self: *DOMNode) void {
        if (self.tag_name) |tag| {
            self.allocator.free(tag);
        }
        if (self.text_content) |text| {
            self.allocator.free(text);
        }
        self.attributes.deinit(self.allocator);
        for (self.children.items) |child| {
            child.deinit();
        }
        self.children.deinit();
    }

    pub fn appendChild(self: *DOMNode, child: *DOMNode) !void {
        child.parent = self;
        try self.children.append(child);
    }

    pub fn removeChild(self: *DOMNode, child: *DOMNode) !void {
        for (self.children.items) |c, i| {
            if (c == child) {
                _ = self.children.remove(i);
                child.parent = null;
                break;
            }
        }
    }

    pub fn querySelector(self: *DOMNode, selector: []const u8) ?*DOMNode {
        // Simple selector implementation (supports tag, .class, #id)
        // For full CSS selector support, we'd need a proper parser

        // Check if selector is just a tag name
        if (!std.mem.contains(u8, selector, ".") and !std.mem.contains(u8, selector, "#")) {
            return self.querySelectorByTag(selector);
        }

        // Check for ID selector
        if (std.mem.startsWith(u8, selector, "#")) {
            return self.querySelectorById(selector[1..]);
        }

        // Check for class selector
        if (std.mem.startsWith(u8, selector, ".")) {
            return self.querySelectorByClass(selector[1..]);
        }

        return null;
    }

    pub fn querySelectorAll(self: *DOMNode, selector: []const u8) []*DOMNode {
        var results = std.ArrayList(*DOMNode).init(self.allocator);
        defer results.deinit();

        // Recursively find all matching nodes
        self.querySelectorAllInternal(selector, &results);

        return results.items;
    }

    fn querySelectorAllInternal(self: *DOMNode, selector: []const u8, results: *std.ArrayList(*DOMNode)) void {
        if (self.matchesSelector(selector)) {
            results.append(self) catch {};
        }

        for (self.children.items) |child| {
            child.querySelectorAllInternal(selector, results);
        }
    }

    pub fn querySelectorByTag(self: *DOMNode, tag: []const u8) ?*DOMNode {
        if (self.tag_name) |t| {
            if (std.mem.eql(u8, t, tag)) {
                return self;
            }
        }

        for (self.children.items) |child| {
            if (child.querySelectorByTag(tag)) |result| {
                return result;
            }
        }

        return null;
    }

    pub fn querySelectorById(self: *DOMNode, id: []const u8) ?*DOMNode {
        if (self.attributes.get("id")) |attr_id| {
            if (std.mem.eql(u8, attr_id, id)) {
                return self;
            }
        }

        for (self.children.items) |child| {
            if (child.querySelectorById(id)) |result| {
                return result;
            }
        }

        return null;
    }

    pub fn querySelectorByClass(self: *DOMNode, class_name: []const u8) ?*DOMNode {
        if (self.attributes.get("class")) |attr_class| {
            const classes = std.mem.split(u8, attr_class, " ");
            for (classes) |cls| {
                if (std.mem.eql(u8, cls, class_name)) {
                    return self;
                }
            }
        }

        for (self.children.items) |child| {
            if (child.querySelectorByClass(class_name)) |result| {
                return result;
            }
        }

        return null;
    }

    pub fn matchesSelector(self: *DOMNode, selector: []const u8) bool {
        // Check tag name
        if (!std.mem.contains(u8, selector, ".") and !std.mem.contains(u8, selector, "#")) {
            if (self.tag_name) |tag| {
                return std.mem.eql(u8, tag, selector);
            }
            return false;
        }

        // Check ID selector
        if (std.mem.startsWith(u8, selector, "#")) {
            if (self.attributes.get("id")) |id| {
                return std.mem.eql(u8, id, selector[1..]);
            }
            return false;
        }

        // Check class selector
        if (std.mem.startsWith(u8, selector, ".")) {
            if (self.attributes.get("class")) |classes| {
                const class_list = std.mem.split(u8, classes, " ");
                for (class_list) |cls| {
                    if (std.mem.eql(u8, cls, selector[1..])) {
                        return true;
                    }
                }
            }
            return false;
        }

        return false;
    }

    pub fn getAttribute(self: *DOMNode, name: []const u8) ?[]const u8 {
        return self.attributes.get(name);
    }

    pub fn setAttribute(self: *DOMNode, name: []const u8, value: []const u8) !void {
        _ = try self.attributes.put(self.allocator.dupe(u8, name), self.allocator.dupe(u8, value));
    }

    pub fn removeAttribute(self: *DOMNode, name: []const u8) void {
        _ = self.attributes.remove(name);
    }

    pub fn getTextContent(self: *DOMNode) []const u8 {
        if (self.text_content) |text| {
            return text;
        }

        // Concatenate text from all text children
        var result = std.ArrayList(u8).init(self.allocator);
        defer result.deinit();

        for (self.children.items) |child| {
            if (child.node_type == .TEXT) {
                if (child.text_content) |text| {
                    result.appendSlice(text) catch {};
                }
            } else {
                const child_text = child.getTextContent();
                result.appendSlice(child_text) catch {};
            }
        }

        return self.allocator.dupe(u8, result.items) catch "";
    }

    pub fn toJson(self: *DOMNode, allocator: std.mem.Allocator) ![]const u8 {
        var json = std.json.StringBuilder.init(allocator);
        defer json.deinit();

        self.toJsonInternal(&json);

        return json.finish();
    }

    fn toJsonInternal(self: *DOMNode, json: *std.json.StringBuilder) void {
        json.objectBegin();

        json.objectField("nodeType");
        json.string(switch (self.node_type) {
            .ELEMENT => "element",
            .TEXT => "text",
            .COMMENT => "comment",
            .DOCUMENT => "document",
        });

        if (self.tag_name) |tag| {
            json.objectField("tagName");
            json.string(tag);
        }

        if (self.text_content) |text| {
            json.objectField("textContent");
            json.string(text);
        }

        if (self.attributes.count() > 0) {
            json.objectField("attributes");
            json.objectBegin();
            var iter = self.attributes.iterator();
            var first = true;
            while (iter.next()) |entry| {
                if (!first) {
                    json.objectField(",");
                }
                json.string(entry.key_ptr.*);
                json.objectField(":");
                json.string(entry.value_ptr.*);
                first = false;
            }
            json.objectEnd();
        }

        if (self.children.items.len > 0) {
            json.objectField("children");
            json.arrayBegin();
            for (self.children.items) |child, i| {
                if (i > 0) {
                    json.arrayField(",");
                }
                child.toJsonInternal(json);
            }
            json.arrayEnd();
        }

        json.objectEnd();
    }
};

pub const DOMParser = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) DOMParser {
        return DOMParser{ .allocator = allocator };
    }

    pub fn parse(self: *DOMParser, html: []const u8) !*DOMNode {
        // For now, implement a very basic HTML parser
        // In production, we'll use GUMBO

        const doc = try DOMNode.init(self.allocator, .DOCUMENT);

        var i: usize = 0;
        while (i < html.len) : (i += 1) {
            if (html[i] == '<') {
                // Parse tag
                if (i + 1 < html.len and html[i + 1] == '/') {
                    // Closing tag, skip for now
                    i += 1;
                    continue;
                }

                const tag_start = i + 1;
                const tag_end = std.mem.indexOf(u8, html[tag_start..], " ") orelse
                    std.mem.indexOf(u8, html[tag_start..], ">") orelse html.len;

                const tag_name = html[tag_start..tag_start + tag_end];

                // Skip to >
                const close_pos = std.mem.indexOf(u8, html[tag_start..], ">") orelse html.len;
                i = tag_start + close_pos;

                // Create element node
                const element = try DOMNode.init(self.allocator, .ELEMENT);
                element.tag_name = try self.allocator.dupe(u8, tag_name);

                // Parse attributes
                const attrs_start = tag_start + tag_end;
                const attrs_end = close_pos;
                const attrs_str = html[attrs_start..attrs_end];

                var attr_i: usize = 0;
                while (attr_i < attrs_str.len) : (attr_i += 1) {
                    const attr_start = std.mem.indexOf(u8, attrs_str[attr_i..], " ") orelse attr_i;
                    if (attr_start == attr_i) {
                        attr_i += 1;
                        continue;
                    }

                    const attr_end = std.mem.indexOf(u8, attrs_str[attr_i..], "=") orelse
                        std.mem.indexOf(u8, attrs_str[attr_i..], " ") orelse attrs_str.len;

                    const attr_name = std.mem.trim(u8, attrs_str[attr_i..attr_i + attr_end], " ");

                    if (attr_end < attrs_str.len and attrs_str[attr_i + attr_end] == '=') {
                        const value_start = attr_i + attr_end + 1;
                        var value_end = value_start;
                        var in_quotes = false;
                        var quote_char: u8 = 0;

                        while (value_end < attrs_str.len) : (value_end += 1) {
                            if (!in_quotes and (attrs_str[value_end] == ' ' or attrs_str[value_end] == '>')) {
                                break;
                            }
                            if (attrs_str[value_end] == '\"' or attrs_str[value_end] == "'") {
                                if (!in_quotes) {
                                    in_quotes = true;
                                    quote_char = attrs_str[value_end];
                                } else if (attrs_str[value_end] == quote_char) {
                                    in_quotes = false;
                                }
                            }
                        }

                        const attr_value = attrs_str[value_start..value_end];
                        _ = try element.setAttribute(attr_name, std.mem.trim(u8, attr_value, "\"'"));

                        attr_i = value_end;
                    } else {
                        // Boolean attribute
                        _ = try element.setAttribute(attr_name, "");
                    }
                }

                try doc.appendChild(element);

                // Parse content until closing tag
                const content_start = i + 1;
                const content_end = std.mem.indexOf(u8, html[content_start..], "</") orelse html.len;

                if (content_end < html.len) {
                    const content = std.mem.trim(u8, html[content_start..content_start + content_end], " ");
                    if (content.len > 0) {
                        const text_node = try DOMNode.init(self.allocator, .TEXT);
                        text_node.text_content = try self.allocator.dupe(u8, content);
                        try element.appendChild(text_node);
                    }

                    i = content_start + content_end - 1; // -1 because the loop will increment
                }
            } else if (html[i] != '\n' and html[i] != '\r' and html[i] != ' ') {
                // Parse text content
                const text_start = i;
                const text_end = std.mem.indexOf(u8, html[text_start..], "<") orelse html.len;

                const text = std.mem.trim(u8, html[text_start..text_start + text_end], " ");
                if (text.len > 0) {
                    const text_node = try DOMNode.init(self.allocator, .TEXT);
                    text_node.text_content = try self.allocator.dupe(u8, text);

                    if (doc.children.items.len > 0) {
                        try doc.children.items[doc.children.items.len - 1].appendChild(text_node);
                    } else {
                        try doc.appendChild(text_node);
                    }
                }

                i = text_start + text_end - 1;
            }
        }

        return doc;
    }
};
