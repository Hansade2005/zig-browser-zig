// Sweef Browser - Logger Utility
// Lightweight logging for the browser core.

const std = @import("std");

pub const LogLevel = enum {
    DEBUG,
    INFO,
    WARN,
    ERROR,
};

pub const ConsoleLog = struct {
    level: LogLevel,
    message: []const u8,
    timestamp: i64,

    pub fn deinit(self: *ConsoleLog, allocator: std.mem.Allocator) void {
        allocator.free(self.message);
    }
};

pub const Logger = struct {
    allocator: std.mem.Allocator,
    min_level: LogLevel,
    output: *std.io.Writer,

    pub fn init(allocator: std.mem.Allocator, min_level: LogLevel, output: *std.io.Writer) Logger {
        return Logger{
            .allocator = allocator,
            .min_level = min_level,
            .output = output,
        };
    }

    pub fn log(self: *Logger, level: LogLevel, message: []const u8) !void {
        if (level < self.min_level) {
            return;
        }

        const timestamp = std.time.timestamp();
        const level_str = switch (level) {
            .DEBUG => "DEBUG",
            .INFO => "INFO",
            .WARN => "WARN",
            .ERROR => "ERROR",
        };

        try self.output.print("[{s}] [{s}] {s}\n", .{ std.fmt.fmtTime(timestamp, .{}), level_str, message });
        try self.output.flush();
    }

    pub fn debug(self: *Logger, message: []const u8) !void {
        try self.log(.DEBUG, message);
    }

    pub fn info(self: *Logger, message: []const u8) !void {
        try self.log(.INFO, message);
    }

    pub fn warn(self: *Logger, message: []const u8) !void {
        try self.log(.WARN, message);
    }

    pub fn error(self: *Logger, message: []const u8) !void {
        try self.log(.ERROR, message);
    }
};

// Global logger instance
var global_logger: ?Logger = null;

pub fn initGlobalLogger(allocator: std.mem.Allocator, min_level: LogLevel) void {
    global_logger = Logger.init(allocator, min_level, std.io.getStdErr().writer());
}

pub fn deinitGlobalLogger() void {
    global_logger = null;
}

pub fn getGlobalLogger() ?*Logger {
    return &global_logger;
}

pub fn log(level: LogLevel, message: []const u8) void {
    if (global_logger) |logger| {
        logger.log(level, message) catch {};
    }
}

pub fn debug(message: []const u8) void {
    log(.DEBUG, message);
}

pub fn info(message: []const u8) void {
    log(.INFO, message);
}

pub fn warn(message: []const u8) void {
    log(.WARN, message);
}

pub fn error(message: []const u8) void {
    log(.ERROR, message);
}
