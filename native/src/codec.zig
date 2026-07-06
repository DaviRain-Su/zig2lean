const std = @import("std");
const c = @cImport({
    @cInclude("ziglean_codec.h");
});

const STATUS_OK: u32 = 0;
const STATUS_INVALID_LENGTH: u32 = 1;
const STATUS_INVALID_DATA: u32 = 2;
const STATUS_ALLOC: u32 = 3;

fn setError(out: *c.ZigLeanCodecResult, status: u32) u32 {
    out.* = .{ .status = status, .reserved = 0, .out_len = 0, .error_offset = 0, .out = null };
    return status;
}

fn setSuccess(out: *c.ZigLeanCodecResult, buf: []u8) u32 {
    out.* = .{ .status = STATUS_OK, .reserved = 0, .out_len = @intCast(buf.len), .error_offset = 0, .out = buf.ptr };
    return STATUS_OK;
}

fn allocBytes(len: usize) ![]u8 {
    return std.heap.c_allocator.alloc(u8, len);
}

export fn ziglean_codec_hex_encode_lower(input: [*]const u8, input_len: u64, out_result: *c.ZigLeanCodecResult) u32 {
    const bytes = input[0..@intCast(input_len)];
    const out = allocBytes(bytes.len * 2) catch return setError(out_result, STATUS_ALLOC);
    const alphabet = "0123456789abcdef";
    for (bytes, 0..) |b, i| {
        out[i * 2] = alphabet[b >> 4];
        out[i * 2 + 1] = alphabet[b & 0x0f];
    }
    return setSuccess(out_result, out);
}

export fn ziglean_codec_hex_decode(input: [*]const u8, input_len: u64, out_result: *c.ZigLeanCodecResult) u32 {
    const encoded = input[0..@intCast(input_len)];
    if (encoded.len % 2 != 0) return setError(out_result, STATUS_INVALID_LENGTH);
    const out = allocBytes(encoded.len / 2) catch return setError(out_result, STATUS_ALLOC);
    _ = std.fmt.hexToBytes(out, encoded) catch |err| {
        std.heap.c_allocator.free(out);
        return switch (err) {
            error.InvalidLength => setError(out_result, STATUS_INVALID_LENGTH),
            else => setError(out_result, STATUS_INVALID_DATA),
        };
    };
    return setSuccess(out_result, out);
}

fn encodeBase64(input: []const u8, out_result: *c.ZigLeanCodecResult, comptime url_safe: bool) u32 {
    const encoder = if (url_safe) std.base64.url_safe_no_pad.Encoder else std.base64.standard.Encoder;
    const out_len = encoder.calcSize(input.len);
    const out = allocBytes(out_len) catch return setError(out_result, STATUS_ALLOC);
    _ = encoder.encode(out, input);
    return setSuccess(out_result, out);
}

fn decodeBase64(input: []const u8, out_result: *c.ZigLeanCodecResult, comptime url_safe: bool) u32 {
    const decoder = if (url_safe) std.base64.url_safe_no_pad.Decoder else std.base64.standard.Decoder;
    const out_len = decoder.calcSizeForSlice(input) catch return setError(out_result, STATUS_INVALID_DATA);
    const out = allocBytes(out_len) catch return setError(out_result, STATUS_ALLOC);
    decoder.decode(out, input) catch |err| {
        std.heap.c_allocator.free(out);
        return switch (err) {
            error.InvalidPadding, error.InvalidCharacter => setError(out_result, STATUS_INVALID_DATA),
            error.NoSpaceLeft => setError(out_result, STATUS_ALLOC),
        };
    };
    return setSuccess(out_result, out);
}

export fn ziglean_codec_base64_encode(input: [*]const u8, input_len: u64, out_result: *c.ZigLeanCodecResult) u32 {
    return encodeBase64(input[0..@intCast(input_len)], out_result, false);
}

export fn ziglean_codec_base64_decode(input: [*]const u8, input_len: u64, out_result: *c.ZigLeanCodecResult) u32 {
    return decodeBase64(input[0..@intCast(input_len)], out_result, false);
}

export fn ziglean_codec_base64url_encode(input: [*]const u8, input_len: u64, out_result: *c.ZigLeanCodecResult) u32 {
    return encodeBase64(input[0..@intCast(input_len)], out_result, true);
}

export fn ziglean_codec_base64url_decode(input: [*]const u8, input_len: u64, out_result: *c.ZigLeanCodecResult) u32 {
    return decodeBase64(input[0..@intCast(input_len)], out_result, true);
}

export fn ziglean_codec_free(ptr: ?[*]u8, len: u64) void {
    if (ptr) |p| {
        std.heap.c_allocator.free(p[0..@intCast(len)]);
    }
}
