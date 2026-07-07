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

const base32_alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";

const base32_map: [256]i8 = blk: {
    var table: [256]i8 = @splat(-1);
    for (base32_alphabet, 0..) |ch, idx| {
        table[@intCast(ch)] = @intCast(idx);
    }
    break :blk table;
};

fn encodeBase32(input: []const u8, out_result: *c.ZigLeanCodecResult) u32 {
    if (input.len == 0) return setSuccess(out_result, &[_]u8{});
    const out_len = ((input.len + 4) / 5) * 8;
    const out = allocBytes(out_len) catch return setError(out_result, STATUS_ALLOC);
    const pad_counts = [_]u8{ 6, 4, 3, 1, 0 };
    var in_idx: usize = 0;
    var out_idx: usize = 0;
    while (in_idx < input.len) {
        var buf: [5]u8 = .{0} ** 5;
        const chunk_len = @min(5, input.len - in_idx);
        @memcpy(buf[0..chunk_len], input[in_idx .. in_idx + chunk_len]);
        out[out_idx] = base32_alphabet[buf[0] >> 3];
        out[out_idx + 1] = base32_alphabet[((buf[0] & 0x07) << 2) | (buf[1] >> 6)];
        out[out_idx + 2] = base32_alphabet[(buf[1] & 0x3e) >> 1];
        out[out_idx + 3] = base32_alphabet[((buf[1] & 0x01) << 4) | (buf[2] >> 4)];
        out[out_idx + 4] = base32_alphabet[((buf[2] & 0x0f) << 1) | (buf[3] >> 7)];
        out[out_idx + 5] = base32_alphabet[(buf[3] & 0x7c) >> 2];
        out[out_idx + 6] = base32_alphabet[((buf[3] & 0x03) << 3) | (buf[4] >> 5)];
        out[out_idx + 7] = base32_alphabet[buf[4] & 0x1f];
        const pad_count = pad_counts[chunk_len - 1];
        for (0..pad_count) |i| {
            out[out_idx + 7 - i] = '=';
        }
        in_idx += chunk_len;
        out_idx += 8;
    }
    return setSuccess(out_result, out);
}

fn decodeBase32(input: []const u8, out_result: *c.ZigLeanCodecResult) u32 {
    if (input.len == 0) return setSuccess(out_result, &[_]u8{});
    if (input.len % 8 != 0) return setError(out_result, STATUS_INVALID_DATA);
    const max_out_len = (input.len / 8) * 5;
    const out = allocBytes(max_out_len) catch return setError(out_result, STATUS_ALLOC);
    var in_idx: usize = 0;
    var out_idx: usize = 0;
    var saw_padding = false;
    while (in_idx < input.len) : (in_idx += 8) {
        var vals: [8]u5 = undefined;
        var valid_count: usize = 8;
        for (input[in_idx .. in_idx + 8], 0..) |ch, i| {
            if (saw_padding and ch != '=') {
                std.heap.c_allocator.free(out);
                return setDecodeError(out_result, @intCast(in_idx + i));
            }
            if (ch == '=') {
                saw_padding = true;
                valid_count = i;
                for (i..8) |j| {
                    if (input[in_idx + j] != '=') {
                        std.heap.c_allocator.free(out);
                        return setError(out_result, STATUS_INVALID_DATA);
                    }
                }
                break;
            }
            const v = base32_map[@intCast(ch)];
            if (v < 0) {
                std.heap.c_allocator.free(out);
                return setDecodeError(out_result, @intCast(in_idx + i));
            }
            vals[i] = @intCast(v);
        }
        const out_count: usize = switch (valid_count) {
            8 => 5,
            7 => 4,
            5 => 3,
            4 => 2,
            2 => 1,
            else => {
                std.heap.c_allocator.free(out);
                return setError(out_result, STATUS_INVALID_DATA);
            },
        };
        var buf: [5]u8 = .{0} ** 5;
        buf[0] = (@as(u8, vals[0]) << 3) | (@as(u8, vals[1]) >> 2);
        if (out_count >= 2) buf[1] = (@as(u8, vals[1]) << 6) | (@as(u8, vals[2]) << 1) | (@as(u8, vals[3]) >> 4);
        if (out_count >= 3) buf[2] = (@as(u8, vals[3]) << 4) | (@as(u8, vals[4]) >> 1);
        if (out_count >= 4) buf[3] = (@as(u8, vals[4]) << 7) | (@as(u8, vals[5]) << 2) | (@as(u8, vals[6]) >> 3);
        if (out_count >= 5) buf[4] = (@as(u8, vals[6]) << 5) | @as(u8, vals[7]);
        @memcpy(out[out_idx .. out_idx + out_count], buf[0..out_count]);
        out_idx += out_count;
    }
    const final_out = allocBytes(out_idx) catch {
        std.heap.c_allocator.free(out);
        return setError(out_result, STATUS_ALLOC);
    };
    @memcpy(final_out, out[0..out_idx]);
    std.heap.c_allocator.free(out);
    return setSuccess(out_result, final_out);
}

export fn ziglean_codec_base32_encode(input: [*]const u8, input_len: u64, out_result: *c.ZigLeanCodecResult) u32 {
    return encodeBase32(input[0..@intCast(input_len)], out_result);
}

export fn ziglean_codec_base32_decode(input: [*]const u8, input_len: u64, out_result: *c.ZigLeanCodecResult) u32 {
    return decodeBase32(input[0..@intCast(input_len)], out_result);
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

export fn ziglean_codec_hex_encode_upper(input: [*]const u8, input_len: u64, out_result: *c.ZigLeanCodecResult) u32 {
    const bytes = input[0..@intCast(input_len)];
    const out = allocBytes(bytes.len * 2) catch return setError(out_result, STATUS_ALLOC);
    const alphabet = "0123456789ABCDEF";
    for (bytes, 0..) |b, i| {
        out[i * 2] = alphabet[b >> 4];
        out[i * 2 + 1] = alphabet[b & 0x0f];
    }
    return setSuccess(out_result, out);
}

// ASCII85 (Adobe variant, no <~> delimiters, no zero-shortcut).
const base85_alphabet = "!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~";

fn encodeBase85(input: []const u8, out_result: *c.ZigLeanCodecResult) u32 {
    if (input.len == 0) return setSuccess(out_result, &[_]u8{});
    const out_len = (input.len + 3) / 4 * 5;
    const out = allocBytes(out_len) catch return setError(out_result, STATUS_ALLOC);
    var in_idx: usize = 0;
    var out_idx: usize = 0;
    while (in_idx < input.len) : (in_idx += 4) {
        const chunk_len = @min(4, input.len - in_idx);
        var buf: [4]u8 = .{0} ** 4;
        @memcpy(buf[0..chunk_len], input[in_idx .. in_idx + chunk_len]);
        var value: u32 = 0;
        for (buf) |b| {
            value = value * 256 + b;
        }
        var digits: [5]u8 = undefined;
        var i: usize = 5;
        var v = value;
        while (i > 0) : (i -= 1) {
            digits[i - 1] = base85_alphabet[@intCast(v % 85)];
            v /= 85;
        }
        const emit = if (chunk_len == 4) 5 else chunk_len + 1;
        @memcpy(out[out_idx .. out_idx + emit], digits[0..emit]);
        out_idx += emit;
    }
    const final_out = allocBytes(out_idx) catch {
        std.heap.c_allocator.free(out);
        return setError(out_result, STATUS_ALLOC);
    };
    @memcpy(final_out, out[0..out_idx]);
    std.heap.c_allocator.free(out);
    return setSuccess(out_result, final_out);
}

fn decodeBase85(input: []const u8, out_result: *c.ZigLeanCodecResult) u32 {
    if (input.len == 0) return setSuccess(out_result, &[_]u8{});
    if (input.len % 5 != 0) return setError(out_result, STATUS_INVALID_LENGTH);
    const max_out_len = input.len / 5 * 4;
    const out = allocBytes(max_out_len) catch return setError(out_result, STATUS_ALLOC);
    var in_idx: usize = 0;
    var out_idx: usize = 0;
    while (in_idx < input.len) : (in_idx += 5) {
        var value: u32 = 0;
        for (input[in_idx .. in_idx + 5], 0..) |ch, i| {
            if (ch < 33 or ch > 117) {
                std.heap.c_allocator.free(out);
                return setDecodeError(out_result, @intCast(in_idx + i));
            }
            value = value * 85 + (@as(u32, ch) - 33);
        }
        var buf: [4]u8 = undefined;
        var v = value;
        var i: usize = 4;
        while (i > 0) : (i -= 1) {
            buf[i - 1] = @intCast(v % 256);
            v /= 256;
        }
        const emit: usize = if (in_idx + 5 == input.len) blk: {
            var last: usize = 4;
            while (last > 0 and buf[last - 1] == 0) : (last -= 1) {}
            break :blk last;
        } else 4;
        @memcpy(out[out_idx .. out_idx + emit], buf[0..emit]);
        out_idx += emit;
    }
    const final_out = allocBytes(out_idx) catch {
        std.heap.c_allocator.free(out);
        return setError(out_result, STATUS_ALLOC);
    };
    @memcpy(final_out, out[0..out_idx]);
    std.heap.c_allocator.free(out);
    return setSuccess(out_result, final_out);
}

export fn ziglean_codec_base85_encode(input: [*]const u8, input_len: u64, out_result: *c.ZigLeanCodecResult) u32 {
    return encodeBase85(input[0..@intCast(input_len)], out_result);
}

export fn ziglean_codec_base85_decode(input: [*]const u8, input_len: u64, out_result: *c.ZigLeanCodecResult) u32 {
    return decodeBase85(input[0..@intCast(input_len)], out_result);
}

export fn ziglean_codec_timing_safe_eq(a: [*]const u8, a_len: u64, b: [*]const u8, b_len: u64) u32 {
    const sa = a[0..@intCast(a_len)];
    const sb = b[0..@intCast(b_len)];
    if (sa.len != sb.len) return 0;
    var acc: u8 = 0;
    for (sa, sb) |x, y| {
        acc |= x ^ y;
    }
    return if (acc == 0) 1 else 0;
}

export fn ziglean_codec_free(ptr: ?[*]u8, len: u64) void {
    if (ptr) |p| {
        std.heap.c_allocator.free(p[0..@intCast(len)]);
    }
}
