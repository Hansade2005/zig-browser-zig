// Sweef Browser - JavaScript Engine (QuickJS Wrapper)
// Lightweight JavaScript engine integration using QuickJS.

const std = @import("std");
const dom = @import("dom");

// QuickJS C API types
const JSContext = extern struct {};
const JSRuntime = extern struct {};
const JSValue = extern union { // Simplified
    int32: i32,
    u32: u32,
    int64: i64,
    float64: f64,
    ptr: [*c]void,
};

// QuickJS C API functions
pub extern fn JS_NewRuntime() [*c]JSRuntime;
pub extern fn JS_FreeRuntime(rt: [*c]JSRuntime) callconv(.C) void;

pub extern fn JS_NewContext(rt: [*c]JSRuntime) [*c]JSContext;
pub extern fn JS_FreeContext(ctx: [*c]JSContext) callconv(.C) void;

pub extern fn JS_Eval(
    ctx: [*c]JSContext,
    input: [*c]const u8,
    input_len: usize,
    filename: [*c]const u8,
    eval_flags: i32,
) callconv(.C) JSValue;

pub extern fn JS_EvalFunction(
    ctx: [*c]JSContext,
    func_obj: JSValue,
) callconv(.C) JSValue;

pub extern fn JS_ToString(ctx: [*c]JSContext, val: JSValue) JSValue;
pub extern fn JS_ToCString(ctx: [*c]JSContext, val: JSValue) [*c]const u8;
pub extern fn JS_ToCStringLen2(
    ctx: [*c]JSContext,
    val: JSValue,
    len: [*c]usize,
) callconv(.C) [*c]const u8;

pub extern fn JS_FreeCString(ctx: [*c]JSContext, str: [*c]const u8) callconv(.C) void;
pub extern fn JS_FreeValue(ctx: [*c]JSContext, val: JSValue) callconv(.C) void;

pub extern fn JS_IsException(val: JSValue) bool;
pub extern fn JS_GetException(ctx: [*c]JSContext) JSValue;

pub extern fn JS_NewObject(ctx: [*c]JSContext) JSValue;
pub extern fn JS_NewArray(ctx: [*c]JSContext) JSValue;
pub extern fn JS_NewString(ctx: [*c]JSContext, str: [*c]const u8) JSValue;
pub extern fn JS_NewStringLen(ctx: [*c]JSContext, str: [*c]const u8, len: usize) JSValue;

pub extern fn JS_SetPropertyStr(
    ctx: [*c]JSContext,
    this_obj: JSValue,
    prop: [*c]const u8,
    val: JSValue,
) callconv(.C) i32;

pub extern fn JS_GetPropertyStr(
    ctx: [*c]JSContext,
    this_obj: JSValue,
    prop: [*c]const u8,
) callconv(.C) JSValue;

pub extern fn JS_DefinePropertyValueStr(
    ctx: [*c]JSContext,
    this_obj: JSValue,
    prop: [*c]const u8,
    val: JSValue,
    flags: i32,
) callconv(.C) i32;

pub extern fn JS_SetGlobalObject(ctx: [*c]JSContext, global_obj: JSValue) callconv(.C) void;
pub extern fn JS_GetGlobalObject(ctx: [*c]JSContext) JSValue;

pub extern fn JS_DupValue(ctx: [*c]JSContext, val: JSValue) JSValue;

pub extern fn JS_NewCFunction(
    ctx: [*c]JSContext,
    func: *const anyopaque,
    name: [*c]const u8,
    length: i32,
) callconv(.C) JSValue;

pub extern fn JS_NewCFunctionData(
    ctx: [*c]JSContext,
    func: *const anyopaque,
    length: i32,
    data: [*c]void,
    data_len: usize,
) callconv(.C) JSValue;

pub extern fn JS_SetHostPromiseRejectionTracker(
    ctx: [*c]JSContext,
    callback: *const anyopaque,
    opaque: [*c]void,
) callconv(.C) void;

pub extern fn JS_NewPromiseCapability(
    ctx: [*c]JSContext,
    resolving_funcs: [*c][*c]JSValue,
) callconv(.C) JSValue;

pub extern fn JS_ResolvePromise(
    ctx: [*c]JSContext,
    promise: JSValue,
    val: JSValue,
) callconv(.C) i32;

pub extern fn JS_RejectPromise(
    ctx: [*c]JSContext,
    promise: JSValue,
    val: JSValue,
) callconv(.C) i32;

pub extern fn JS_NewInt32(ctx: [*c]JSContext, val: i32) JSValue;
pub extern fn JS_NewInt64(ctx: [*c]JSContext, val: i64) JSValue;
pub extern fn JS_NewFloat64(ctx: [*c]JSContext, val: f64) JSValue;
pub extern fn JS_NewBool(ctx: [*c]JSContext, val: bool) JSValue;
pub extern fn JS_UNDEFINED JSValue;
pub extern fn JS_NULL JSValue;

pub extern fn JS_IsUndefined(val: JSValue) bool;
pub extern fn JS_IsNull(val: JSValue) bool;
pub extern fn JS_IsNumber(val: JSValue) bool;
pub extern fn JS_IsString(val: JSValue) bool;
pub extern fn JS_IsBoolean(val: JSValue) bool;
pub extern fn JS_IsObject(val: JSValue) bool;
pub extern fn JS_IsFunction(ctx: [*c]JSContext, val: JSValue) bool;

pub extern fn JS_ToInt32(ctx: [*c]JSContext, val: JSValue) i32;
pub extern fn JS_ToInt64(ctx: [*c]JSContext, val: JSValue) i64;
pub extern fn JS_ToFloat64(ctx: [*c]JSContext, val: JSValue) f64;
pub extern fn JS_ToBool(ctx: [*c]JSContext, val: JSValue) bool;

pub extern fn JS_Throw(ctx: [*c]JSContext, val: JSValue) callconv(.C) void;

pub extern fn JS_NewArrayBuffer(
    ctx: [*c]JSContext,
    buf: [*c]u8,
    len: usize,
) callconv(.C) JSValue;

pub extern fn JS_GetArrayBuffer(ctx: [*c]JSContext, val: JSValue, len: [*c]usize) [*c]u8;

// QuickJS constants
pub const JS_EVAL_FLAG_STRICT: i32 = 1;
pub const JS_EVAL_FLAG_STRICT | JS_EVAL_FLAG_MODULE: i32 = 1 | 2;

pub const JS_PROP_CONFIGURABLE: i32 = 1;
pub const JS_PROP_WRITABLE: i32 = 2;
pub const JS_PROP_ENUMERABLE: i32 = 4;
pub const JS_PROP_C_W_E: i32 = JS_PROP_CONFIGURABLE | JS_PROP_WRITABLE | JS_PROP_ENUMERABLE;

pub const JSEngine = struct {
    runtime: [*c]JSRuntime,
    allocator: std.mem.Allocator,

    pub fn init() !*JSEngine {
        const runtime = JS_NewRuntime();
        if (runtime == null) {
            return error.JSRuntimeCreationFailed;
        }

        return &JSEngine{
            .runtime = runtime,
            .allocator = std.heap.page_allocator,
        };
    }

    pub fn deinit(self: *JSEngine) void {
        JS_FreeRuntime(self.runtime);
    }

    pub fn newContext(self: *JSEngine) !*JSContext {
        const ctx = JS_NewContext(self.runtime);
        if (ctx == null) {
            return error.JSContextCreationFailed;
        }

        return JSContext.init(self.allocator, ctx);
    }
};

pub const JSContext = struct {
    allocator: std.mem.Allocator,
    ctx: [*c]JSContext,
    page: ?*anyopaque, // Reference to Page for DOM bindings

    pub fn init(allocator: std.mem.Allocator, ctx: [*c]JSContext) !*JSContext {
        return &JSContext{
            .allocator = allocator,
            .ctx = ctx,
            .page = null,
        };
    }

    pub fn deinit(self: *JSContext) void {
        JS_FreeContext(self.ctx);
    }

    pub fn evaluate(self: *JSContext, js: []const u8) ![]const u8 {
        const c_js = self.allocator.alloc(u8, js.len + 1);
        @memcpy(c_js, js);
        c_js[js.len] = 0;

        const val = JS_Eval(self.ctx, c_js, js.len, "script.js", 0);
        self.allocator.free(c_js);

        if (JS_IsException(val)) {
            const exception = JS_GetException(self.ctx);
            const error_msg = JS_ToCString(self.ctx, exception);
            const result = self.allocator.dupe(u8, error_msg);
            JS_FreeCString(self.ctx, error_msg);
            JS_FreeValue(self.ctx, exception);
            JS_FreeValue(self.ctx, val);
            return error.JSEvalError;
        }

        const result_val = JS_ToString(self.ctx, val);
        const result_str = JS_ToCString(self.ctx, result_val);
        const result = self.allocator.dupe(u8, result_str);

        JS_FreeCString(self.ctx, result_str);
        JS_FreeValue(self.ctx, result_val);
        JS_FreeValue(self.ctx, val);

        return result;
    }

    pub fn setPage(self: *JSContext, page: *anyopaque) void {
        self.page = page;
    }

    pub fn setupDOMBindings(self: *JSContext, dom_node: *dom.DOMNode) !void {
        // Create global object bindings
        const global = JS_GetGlobalObject(self.ctx);

        // Create console object
        const console_obj = JS_NewObject(self.ctx);
        
        // console.log
        const console_log_func = JS_NewCFunction(
            self.ctx,
            @ptrCast([*c]const anyopaque, &js_console_log),
            "log",
            1,
        );
        _ = JS_SetPropertyStr(self.ctx, console_obj, "log", console_log_func);

        // console.error
        const console_error_func = JS_NewCFunction(
            self.ctx,
            @ptrCast([*c]const anyopaque, &js_console_error),
            "error",
            1,
        );
        _ = JS_SetPropertyStr(self.ctx, console_obj, "error", console_error_func);

        // console.warn
        const console_warn_func = JS_NewCFunction(
            self.ctx,
            @ptrCast([*c]const anyopaque, &js_console_warn),
            "warn",
            1,
        );
        _ = JS_SetPropertyStr(self.ctx, console_obj, "warn", console_warn_func);

        _ = JS_SetPropertyStr(self.ctx, global, "console", console_obj);

        // Create document object (simplified)
        const document_obj = JS_NewObject(self.ctx);
        
        // document.querySelector
        const query_selector_func = JS_NewCFunctionData(
            self.ctx,
            @ptrCast([*c]const anyopaque, &js_query_selector),
            1,
            @ptrCast([*c]void, dom_node),
            @sizeOf(*dom.DOMNode),
        );
        _ = JS_SetPropertyStr(self.ctx, document_obj, "querySelector", query_selector_func);

        // document.getElementById
        const get_element_by_id_func = JS_NewCFunctionData(
            self.ctx,
            @ptrCast([*c]const anyopaque, &js_get_element_by_id),
            1,
            @ptrCast([*c]void, dom_node),
            @sizeOf(*dom.DOMNode),
        );
        _ = JS_SetPropertyStr(self.ctx, document_obj, "getElementById", get_element_by_id_func);

        // document.createElement
        const create_element_func = JS_NewCFunctionData(
            self.ctx,
            @ptrCast([*c]const anyopaque, &js_create_element),
            1,
            @ptrCast([*c]void, dom_node),
            @sizeOf(*dom.DOMNode),
        );
        _ = JS_SetPropertyStr(self.ctx, document_obj, "createElement", create_element_func);

        _ = JS_SetPropertyStr(self.ctx, global, "document", document_obj);

        // Create window object (simplified)
        const window_obj = JS_NewObject(self.ctx);
        
        // window.document
        _ = JS_SetPropertyStr(self.ctx, window_obj, "document", JS_DupValue(self.ctx, document_obj));

        // window.console
        _ = JS_SetPropertyStr(self.ctx, window_obj, "console", JS_DupValue(self.ctx, console_obj));

        // window.setTimeout
        const set_timeout_func = JS_NewCFunctionData(
            self.ctx,
            @ptrCast([*c]const anyopaque, &js_set_timeout),
            2,
            @ptrCast([*c]void, self),
            @sizeOf(*JSContext),
        );
        _ = JS_SetPropertyStr(self.ctx, window_obj, "setTimeout", set_timeout_func);

        // window.clearTimeout
        const clear_timeout_func = JS_NewCFunctionData(
            self.ctx,
            @ptrCast([*c]const anyopaque, &js_clear_timeout),
            1,
            @ptrCast([*c]void, self),
            @sizeOf(*JSContext),
        );
        _ = JS_SetPropertyStr(self.ctx, window_obj, "clearTimeout", clear_timeout_func);

        _ = JS_SetPropertyStr(self.ctx, global, "window", window_obj);
        JS_FreeValue(self.ctx, global);
    }
};

// C callbacks for QuickJS
fn js_console_log(
    ctx: [*c]JSContext,
    this_val: JSValue,
    argc: i32,
    argv: [*c]JSValue,
) callconv(.C) JSValue {
    if (argc < 1) {
        return JS_UNDEFINED;
    }

    const arg = argv[0];
    const str = JS_ToCString(ctx, arg);
    std.debug.print("JS LOG: {s}\n", .{str});
    JS_FreeCString(ctx, str);
    
    return JS_UNDEFINED;
}

fn js_console_error(
    ctx: [*c]JSContext,
    this_val: JSValue,
    argc: i32,
    argv: [*c]JSValue,
) callconv(.C) JSValue {
    if (argc < 1) {
        return JS_UNDEFINED;
    }

    const arg = argv[0];
    const str = JS_ToCString(ctx, arg);
    std.debug.print("JS ERROR: {s}\n", .{str});
    JS_FreeCString(ctx, str);
    
    return JS_UNDEFINED;
}

fn js_console_warn(
    ctx: [*c]JSContext,
    this_val: JSValue,
    argc: i32,
    argv: [*c]JSValue,
) callconv(.C) JSValue {
    if (argc < 1) {
        return JS_UNDEFINED;
    }

    const arg = argv[0];
    const str = JS_ToCString(ctx, arg);
    std.debug.print("JS WARN: {s}\n", .{str});
    JS_FreeCString(ctx, str);
    
    return JS_UNDEFINED;
}

fn js_query_selector(
    ctx: [*c]JSContext,
    this_val: JSValue,
    argc: i32,
    argv: [*c]JSValue,
    data: [*c]void,
) callconv(.C) JSValue {
    if (argc < 1) {
        return JS_NULL;
    }

    const dom_node_ptr = @ptrCast([*]dom.DOMNode, data);
    const selector = JS_ToCString(ctx, argv[0]);
    defer JS_FreeCString(ctx, selector);

    if (dom_node_ptr.querySelector(selector)) |node| {
        // Return a simple object representing the element
        const element_obj = JS_NewObject(ctx);
        if (node.tag_name) |tag| {
            const tag_str = JS_NewString(ctx, tag);
            _ = JS_SetPropertyStr(ctx, element_obj, "tagName", tag_str);
        }
        return element_obj;
    }

    return JS_NULL;
}

fn js_get_element_by_id(
    ctx: [*c]JSContext,
    this_val: JSValue,
    argc: i32,
    argv: [*c]JSValue,
    data: [*c]void,
) callconv(.C) JSValue {
    if (argc < 1) {
        return JS_NULL;
    }

    const dom_node_ptr = @ptrCast([*]dom.DOMNode, data);
    const id = JS_ToCString(ctx, argv[0]);
    defer JS_FreeCString(ctx, id);

    if (dom_node_ptr.querySelectorById(id)) |node| {
        const element_obj = JS_NewObject(ctx);
        if (node.tag_name) |tag| {
            const tag_str = JS_NewString(ctx, tag);
            _ = JS_SetPropertyStr(ctx, element_obj, "tagName", tag_str);
        }
        return element_obj;
    }

    return JS_NULL;
}

fn js_create_element(
    ctx: [*c]JSContext,
    this_val: JSValue,
    argc: i32,
    argv: [*c]JSValue,
    data: [*c]void,
) callconv(.C) JSValue {
    if (argc < 1) {
        return JS_NULL;
    }

    const dom_node_ptr = @ptrCast([*]dom.DOMNode, data);
    const tag_name = JS_ToCString(ctx, argv[0]);
    defer JS_FreeCString(ctx, tag_name);

    // In a real implementation, we'd create a new DOM node
    // For now, just return a simple object
    const element_obj = JS_NewObject(ctx);
    const tag_str = JS_NewString(ctx, tag_name);
    _ = JS_SetPropertyStr(ctx, element_obj, "tagName", tag_str);
    
    return element_obj;
}

// Timeout handling
var timeout_map: std.StringHashMap(*std.Thread) = .{};
var timeout_counter: u32 = 0;

fn js_set_timeout(
    ctx: [*c]JSContext,
    this_val: JSValue,
    argc: i32,
    argv: [*c]JSValue,
    data: [*c]void,
) callconv(.C) JSValue {
    if (argc < 2) {
        return JS_UNDEFINED;
    }

    const js_ctx_ptr = @ptrCast([*]JSContext, data);
    const callback = argv[0];
    const delay_ms = JS_ToInt32(ctx, argv[1]);

    // In a real implementation, we'd schedule the callback
    // For now, just log it
    std.debug.print("setTimeout called with delay {d}ms\n", .{delay_ms});

    // Return a timeout ID
    timeout_counter += 1;
    const id_str = std.fmt.allocPrint(js_ctx_ptr.allocator, "{d}", .{timeout_counter}) orelse return JS_UNDEFINED;
    const id = JS_NewString(ctx, id_str);
    js_ctx_ptr.allocator.free(id_str);
    
    return id;
}

fn js_clear_timeout(
    ctx: [*c]JSContext,
    this_val: JSValue,
    argc: i32,
    argv: [*c]JSValue,
    data: [*c]void,
) callconv(.C) JSValue {
    if (argc < 1) {
        return JS_UNDEFINED;
    }

    const id = JS_ToCString(ctx, argv[0]);
    defer JS_FreeCString(ctx, id);

    std.debug.print("clearTimeout called with ID {s}\n", .{id});

    return JS_UNDEFINED;
}

// Error types
pub const JSEngineError = error{
    JSRuntimeCreationFailed,
    JSContextCreationFailed,
    JSEvalError,
    JSAllocationFailed,
};
