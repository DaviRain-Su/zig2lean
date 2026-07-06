const std = @import("std");
const c = @cImport({
    @cInclude("ziglean_json.h");
});

export fn ziglean_json_validate(input: [*]const u8, input_len: u64) u32 {
    const bytes = input[0..@intCast(input_len)];
    var scanner = std.json.Scanner.initCompleteInput(std.heap.c_allocator, bytes);
    defer scanner.deinit();

    while (true) {
        const token = scanner.next() catch return 1;
        switch (token) {
            .end_of_document => return 0,
            else => {},
        }
    }
}

const TokenList = std.ArrayList(c.ZigLeanJsonToken);

fn appendToken(list: *TokenList, kind: u32, offset: usize, length: usize) !void {
    try list.append(std.heap.c_allocator, .{
        .kind = kind,
        .reserved = 0,
        .offset = @intCast(offset),
        .length = @intCast(length),
    });
}

fn spanFromSlice(input: []const u8, slice: []const u8) struct { offset: usize, length: usize } {
    const start = @intFromPtr(slice.ptr) - @intFromPtr(input.ptr);
    return .{ .offset = start, .length = slice.len };
}

export fn ziglean_json_parse_tokens(
    input: [*]const u8,
    input_len: u64,
    out_tokens: *?[*]c.ZigLeanJsonToken,
    out_len: *u64,
    out_error: *c.ZigLeanJsonError,
) u32 {
    const bytes = input[0..@intCast(input_len)];
    var scanner = std.json.Scanner.initCompleteInput(std.heap.c_allocator, bytes);
    defer scanner.deinit();

    var list = TokenList.empty;
    errdefer list.deinit(std.heap.c_allocator);

    while (true) {
        const before = scanner.cursor;
        const token = scanner.next() catch {
            out_tokens.* = null;
            out_len.* = 0;
            out_error.* = .{ .code = 1, .reserved = 0, .offset = @intCast(scanner.cursor) };
            return 1;
        };
        const after = scanner.cursor;
        switch (token) {
            .object_begin => appendToken(&list, 1, after - 1, 1) catch return 2,
            .object_end => appendToken(&list, 2, after - 1, 1) catch return 2,
            .array_begin => appendToken(&list, 3, after - 1, 1) catch return 2,
            .array_end => appendToken(&list, 4, after - 1, 1) catch return 2,
            .string => |s| {
                const span = spanFromSlice(bytes, s);
                appendToken(&list, 5, span.offset, span.length) catch return 2;
            },
            .number => |s| {
                const span = spanFromSlice(bytes, s);
                appendToken(&list, 6, span.offset, span.length) catch return 2;
            },
            .true => appendToken(&list, 7, after - 4, 4) catch return 2,
            .false => appendToken(&list, 7, after - 5, 5) catch return 2,
            .null => appendToken(&list, 8, after - 4, 4) catch return 2,
            .end_of_document => {
                out_len.* = @intCast(list.items.len);
                const owned = list.toOwnedSlice(std.heap.c_allocator) catch return 2;
                out_tokens.* = owned.ptr;
                out_error.* = .{ .code = 0, .reserved = 0, .offset = 0 };
                return 0;
            },
            else => {
                out_tokens.* = null;
                out_len.* = 0;
                out_error.* = .{ .code = 3, .reserved = 0, .offset = @intCast(before) };
                return 3;
            },
        }
    }
}

export fn ziglean_json_free_tokens(tokens: ?[*]c.ZigLeanJsonToken, len: u64) void {
    if (tokens) |ptr| {
        const slice = ptr[0..@intCast(len)];
        std.heap.c_allocator.free(slice);
    }
}
