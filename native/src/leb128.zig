const std = @import("std");
const c = @cImport({
    @cInclude("ziglean_leb128.h");
});

const STATUS_OK: u32 = 0;
const STATUS_INVALID: u32 = 1;
const STATUS_ALLOC: u32 = 2;

fn setError(out: *c.ZigLeanLeb128Result, status: u32) u32 {
    out.* = .{ .status = status, .reserved = 0, .out_len = 0, .value = 0, .out = null };
    return status;
}

fn setEncodeSuccess(out: *c.ZigLeanLeb128Result, buf: []u8) u32 {
    out.* = .{ .status = STATUS_OK, .reserved = 0, .out_len = @intCast(buf.len), .value = 0, .out = buf.ptr };
    return STATUS_OK;
}

fn setDecodeSuccess(out: *c.ZigLeanLeb128Result, value: u64) u32 {
    out.* = .{ .status = STATUS_OK, .reserved = 0, .out_len = 0, .value = value, .out = null };
    return STATUS_OK;
}

fn encodeUleb128(value: u64) ![]u8 {
    var buf: [10]u8 = undefined;
    var idx: usize = 0;
    var v = value;
    while (true) {
        var byte: u8 = @truncate(v & 0x7f);
        v >>= 7;
        if (v != 0) byte |= 0x80;
        buf[idx] = byte;
        idx += 1;
        if (v == 0) break;
    }
    return std.heap.c_allocator.dupe(u8, buf[0..idx]) catch error.OutOfMemory;
}

fn encodeSleb128(value: i64) ![]u8 {
    var buf: [10]u8 = undefined;
    var idx: usize = 0;
    var v: i64 = value;
    while (true) {
        var byte: u8 = @truncate(@as(u64, @bitCast(v)) & 0x7f);
        v >>= 7;
        const sign_extend = (byte & 0x40) != 0;
        const done = (v == 0 and !sign_extend) or (v == -1 and sign_extend);
        if (!done) byte |= 0x80;
        buf[idx] = byte;
        idx += 1;
        if (done) break;
    }
    return std.heap.c_allocator.dupe(u8, buf[0..idx]) catch error.OutOfMemory;
}

export fn ziglean_leb128_encode_u64(value: u64, out_result: *c.ZigLeanLeb128Result) u32 {
    const out = encodeUleb128(value) catch return setError(out_result, STATUS_ALLOC);
    return setEncodeSuccess(out_result, out);
}

export fn ziglean_leb128_decode_u64(input: [*]const u8, input_len: u64, out_result: *c.ZigLeanLeb128Result) u32 {
    var reader: std.Io.Reader = .fixed(input[0..@intCast(input_len)]);
    const value = reader.takeLeb128(u64) catch return setError(out_result, STATUS_INVALID);
    return setDecodeSuccess(out_result, value);
}

export fn ziglean_leb128_encode_i64(value: i64, out_result: *c.ZigLeanLeb128Result) u32 {
    const out = encodeSleb128(value) catch return setError(out_result, STATUS_ALLOC);
    return setEncodeSuccess(out_result, out);
}

export fn ziglean_leb128_decode_i64(input: [*]const u8, input_len: u64, out_result: *c.ZigLeanLeb128Result) u32 {
    var reader: std.Io.Reader = .fixed(input[0..@intCast(input_len)]);
    const value = reader.takeLeb128(i64) catch return setError(out_result, STATUS_INVALID);
    return setDecodeSuccess(out_result, @bitCast(value));
}

export fn ziglean_leb128_free(ptr: ?[*]u8, len: u64) void {
    if (ptr) |p| {
        std.heap.c_allocator.free(p[0..@intCast(len)]);
    }
}