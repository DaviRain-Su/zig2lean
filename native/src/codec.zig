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

const base58_alphabet = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";

const base58_map: [256]i8 = blk: {
    var table: [256]i8 = @splat(-1);
    for (base58_alphabet, 0..) |ch, idx| {
        table[@intCast(ch)] = @intCast(idx);
    }
    break :blk table;
};

fn setDecodeError(out_result: *c.ZigLeanCodecResult, offset: u64) u32 {
    out_result.* = .{ .status = STATUS_INVALID_DATA, .reserved = 0, .out_len = 0, .error_offset = offset, .out = null };
    return STATUS_INVALID_DATA;
}

fn base58Encode(input: []const u8, out_result: *c.ZigLeanCodecResult) u32 {
    var zeros: usize = 0;
    while (zeros < input.len and input[zeros] == 0) : (zeros += 1) {}

    if (zeros == input.len) {
        const out = allocBytes(zeros) catch return setError(out_result, STATUS_ALLOC);
        @memset(out, base58_alphabet[0]);
        return setSuccess(out_result, out);
    }

    const b58_len = (input.len - zeros) * 138 / 100 + 1;
    const b58 = std.heap.c_allocator.alloc(u8, b58_len) catch return setError(out_result, STATUS_ALLOC);
    defer std.heap.c_allocator.free(b58);
    @memset(b58, 0);

    for (input[zeros..]) |byte| {
        var carry: u32 = byte;
        var j: usize = b58_len;
        while (j > 0) {
            j -= 1;
            carry += @as(u32, b58[j]) * 256;
            b58[j] = @intCast(carry % 58);
            carry /= 58;
        }
    }

    var start: usize = 0;
    while (start < b58_len and b58[start] == 0) : (start += 1) {}

    const out_len = zeros + (b58_len - start);
    const out = allocBytes(out_len) catch return setError(out_result, STATUS_ALLOC);
    if (zeros > 0) @memset(out[0..zeros], base58_alphabet[0]);
    for (b58[start..], 0..) |digit, i| {
        out[zeros + i] = base58_alphabet[digit];
    }
    return setSuccess(out_result, out);
}

fn base58Decode(input: []const u8, out_result: *c.ZigLeanCodecResult) u32 {
    var zeros: usize = 0;
    while (zeros < input.len and input[zeros] == base58_alphabet[0]) : (zeros += 1) {}

    if (zeros == input.len) {
        const out = allocBytes(zeros) catch return setError(out_result, STATUS_ALLOC);
        @memset(out, 0);
        return setSuccess(out_result, out);
    }

    const bin_len = (input.len - zeros) * 733 / 1000 + 1;
    const bin = std.heap.c_allocator.alloc(u8, bin_len) catch return setError(out_result, STATUS_ALLOC);
    defer std.heap.c_allocator.free(bin);
    @memset(bin, 0);

    for (input[zeros..], 0..) |ch, rel| {
        const val = base58_map[@intCast(ch)];
        if (val < 0) return setDecodeError(out_result, @intCast(zeros + rel));

        var carry: u32 = @intCast(val);
        var j: usize = bin_len;
        while (j > 0) {
            j -= 1;
            carry += @as(u32, bin[j]) * 58;
            bin[j] = @intCast(carry % 256);
            carry /= 256;
        }
        if (carry != 0) return setDecodeError(out_result, @intCast(zeros + rel));
    }

    var start: usize = 0;
    while (start < bin_len and bin[start] == 0) : (start += 1) {}

    const out_len = zeros + (bin_len - start);
    const out = allocBytes(out_len) catch return setError(out_result, STATUS_ALLOC);
    if (zeros > 0) @memset(out[0..zeros], 0);
    @memcpy(out[zeros..], bin[start..]);
    return setSuccess(out_result, out);
}

export fn ziglean_codec_base58_encode(input: [*]const u8, input_len: u64, out_result: *c.ZigLeanCodecResult) u32 {
    return base58Encode(input[0..@intCast(input_len)], out_result);
}

export fn ziglean_codec_base58_decode(input: [*]const u8, input_len: u64, out_result: *c.ZigLeanCodecResult) u32 {
    return base58Decode(input[0..@intCast(input_len)], out_result);
}

export fn ziglean_codec_free(ptr: ?[*]u8, len: u64) void {
    if (ptr) |p| {
        std.heap.c_allocator.free(p[0..@intCast(len)]);
    }
}
