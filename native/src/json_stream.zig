const std = @import("std");
const c = @cImport({
    @cInclude("ziglean_json_stream.h");
});

const STATUS_OK: u32 = 0;
const STATUS_INVALID: u32 = 1;
const STATUS_ALLOC: u32 = 2;

const StringSpan = struct {
    start: u64,
    end: u64,
};

const StreamCtx = struct {
    scanner: std.json.Scanner,
    diagnostics: std.json.Diagnostics,
    buffer: std.ArrayList(u8),
    pending_string: ?StringSpan,
    input_ended: bool,
    finished: bool,

    fn deinit(self: *StreamCtx) void {
        self.scanner.deinit();
        self.buffer.deinit(std.heap.c_allocator);
    }
};

fn globalBase(ctx: *StreamCtx) u64 {
    return ctx.diagnostics.total_bytes_before_current_input;
}

fn spanFromSlice(input: []const u8, slice: []const u8) struct { offset: usize, length: usize } {
    const start = @intFromPtr(slice.ptr) - @intFromPtr(input.ptr);
    return .{ .offset = start, .length = slice.len };
}

fn extendStringSpan(span: *?StringSpan, start: u64, end: u64) void {
    if (span.*) |current| {
        span.* = .{ .start = current.start, .end = end };
    } else {
        span.* = .{ .start = start, .end = end };
    }
}

fn setResult(out: *c.ZigLeanJsonStreamResult, status: u32, kind: u32, offset: u64, length: u64, error_offset: u64) void {
    out.* = .{
        .status = status,
        .kind = kind,
        .offset = offset,
        .length = length,
        .error_offset = error_offset,
    };
}

fn emitToken(out: *c.ZigLeanJsonStreamResult, kind: u32, offset: u64, length: u64) void {
    setResult(out, c.ZIGLEAN_JSON_STREAM_TOKEN, kind, offset, length, 0);
}

fn emitNeedMore(out: *c.ZigLeanJsonStreamResult) void {
    setResult(out, c.ZIGLEAN_JSON_STREAM_NEED_MORE, 0, 0, 0, 0);
}

fn emitError(out: *c.ZigLeanJsonStreamResult, offset: u64) void {
    setResult(out, c.ZIGLEAN_JSON_STREAM_ERROR, 0, 0, 0, offset);
}

fn emitEnd(out: *c.ZigLeanJsonStreamResult) void {
    setResult(out, c.ZIGLEAN_JSON_STREAM_END, 0, 0, 0, 0);
}

export fn ziglean_json_stream_init(out_handle: *?*anyopaque) u32 {
    const ctx = std.heap.c_allocator.create(StreamCtx) catch return STATUS_ALLOC;
    ctx.* = .{
        .scanner = std.json.Scanner.initStreaming(std.heap.c_allocator),
        .diagnostics = .{},
        .buffer = std.ArrayList(u8).empty,
        .pending_string = null,
        .input_ended = false,
        .finished = false,
    };
    ctx.scanner.enableDiagnostics(&ctx.diagnostics);
    out_handle.* = ctx;
    return STATUS_OK;
}

export fn ziglean_json_stream_feed(handle: ?*anyopaque, input: [*]const u8, input_len: u64) u32 {
    const ctx: *StreamCtx = @ptrCast(@alignCast(handle orelse return STATUS_INVALID));
    if (ctx.finished) return STATUS_INVALID;
    const chunk = input[0..@intCast(input_len)];
    ctx.buffer.appendSlice(std.heap.c_allocator, chunk) catch return STATUS_ALLOC;
    ctx.scanner.feedInput(chunk);
    return STATUS_OK;
}

export fn ziglean_json_stream_end_input(handle: ?*anyopaque) void {
    const ctx: *StreamCtx = @ptrCast(@alignCast(handle orelse return));
    ctx.input_ended = true;
    ctx.scanner.endInput();
}

export fn ziglean_json_stream_next(handle: ?*anyopaque, out_result: *c.ZigLeanJsonStreamResult) u32 {
    const ctx: *StreamCtx = @ptrCast(@alignCast(handle orelse return STATUS_INVALID));
    if (ctx.finished) {
        emitEnd(out_result);
        return STATUS_OK;
    }

    const bytes = ctx.scanner.input;
    const base = globalBase(ctx);

    while (true) {
        const before = ctx.scanner.cursor;
        const token = ctx.scanner.next() catch |err| switch (err) {
            error.BufferUnderrun => {
                if (!ctx.input_ended) {
                    emitNeedMore(out_result);
                    return STATUS_OK;
                }
                emitError(out_result, ctx.diagnostics.getByteOffset());
                return STATUS_OK;
            },
            else => {
                emitError(out_result, ctx.diagnostics.getByteOffset());
                return STATUS_OK;
            },
        };
        const after = ctx.scanner.cursor;

        switch (token) {
            .object_begin => {
                emitToken(out_result, 1, ctx.diagnostics.getByteOffset() - 1, 1);
                return STATUS_OK;
            },
            .object_end => {
                emitToken(out_result, 2, ctx.diagnostics.getByteOffset() - 1, 1);
                return STATUS_OK;
            },
            .array_begin => {
                emitToken(out_result, 3, ctx.diagnostics.getByteOffset() - 1, 1);
                return STATUS_OK;
            },
            .array_end => {
                emitToken(out_result, 4, ctx.diagnostics.getByteOffset() - 1, 1);
                return STATUS_OK;
            },
            .string => |s| {
                if (ctx.pending_string) |span| {
                    const end = if (s.len > 0) blk: {
                        const tail = spanFromSlice(bytes, s);
                        break :blk base + tail.offset + tail.length;
                    } else span.end;
                    emitToken(out_result, 5, span.start, end - span.start);
                    ctx.pending_string = null;
                } else {
                    const span = spanFromSlice(bytes, s);
                    emitToken(out_result, 5, base + span.offset, span.length);
                }
                return STATUS_OK;
            },
            .partial_string => |s| {
                const span = spanFromSlice(bytes, s);
                extendStringSpan(&ctx.pending_string, base + span.offset, base + span.offset + span.length);
            },
            .partial_string_escaped_1 => {
                extendStringSpan(&ctx.pending_string, base + (after - 2), base + after);
            },
            .partial_string_escaped_2 => {
                extendStringSpan(&ctx.pending_string, base + (after - 6), base + after);
            },
            .partial_string_escaped_3 => {
                extendStringSpan(&ctx.pending_string, base + (after - 6), base + after);
            },
            .partial_string_escaped_4 => {
                extendStringSpan(&ctx.pending_string, base + (after - 12), base + after);
            },
            .number => |s| {
                const span = spanFromSlice(bytes, s);
                emitToken(out_result, 6, base + span.offset, span.length);
                return STATUS_OK;
            },
            .true => {
                emitToken(out_result, 7, ctx.diagnostics.getByteOffset() - 4, 4);
                return STATUS_OK;
            },
            .false => {
                emitToken(out_result, 8, ctx.diagnostics.getByteOffset() - 5, 5);
                return STATUS_OK;
            },
            .null => {
                emitToken(out_result, 8, ctx.diagnostics.getByteOffset() - 4, 4);
                return STATUS_OK;
            },
            .end_of_document => {
                ctx.finished = true;
                emitEnd(out_result);
                return STATUS_OK;
            },
            else => {
                emitError(out_result, base + before);
                return STATUS_OK;
            },
        }
    }
}

export fn ziglean_json_stream_free(handle: ?*anyopaque) void {
    if (handle) |ptr| {
        const ctx: *StreamCtx = @ptrCast(@alignCast(ptr));
        ctx.deinit();
        std.heap.c_allocator.destroy(ctx);
    }
}