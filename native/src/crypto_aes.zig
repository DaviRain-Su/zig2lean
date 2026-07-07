const std = @import("std");
const Aes = std.crypto.core.aes;
const ctr = std.crypto.core.modes.ctr;
const c = @cImport({
    @cInclude("ziglean_crypto_aes.h");
});

const STATUS_OK: u32 = 0;
const STATUS_INVALID: u32 = 1;
const STATUS_ALLOC: u32 = 2;

const blk: usize = 16;
const key_len: usize = Aes.Aes256.key_bits / 8;

fn setError(out: *c.ZigLeanCipherResult, status: u32) u32 {
    out.* = .{ .status = status, .reserved = 0, .out_len = 0, .out = null };
    return status;
}

fn setSuccess(out: *c.ZigLeanCipherResult, buf: []u8) u32 {
    out.* = .{ .status = STATUS_OK, .reserved = 0, .out_len = @intCast(buf.len), .out = buf.ptr };
    return STATUS_OK;
}

export fn ziglean_crypto_aes256_ctr(
    key: [*]const u8,
    iv: [*]const u8,
    iv_len: u64,
    input: [*]const u8,
    input_len: u64,
    out_result: *c.ZigLeanCipherResult,
) u32 {
    if (iv_len != blk) return setError(out_result, STATUS_INVALID);
    const out = std.heap.c_allocator.alloc(u8, @intCast(input_len)) catch return setError(out_result, STATUS_ALLOC);
    const enc = Aes.Aes256.initEnc(key[0..key_len].*);
    const iv_block: [blk]u8 = iv[0..blk].*;
    ctr(Aes.AesEncryptCtx(Aes.Aes256), enc, out, input[0..@intCast(input_len)], iv_block, .big);
    return setSuccess(out_result, out);
}

export fn ziglean_crypto_aes256_cbc_encrypt(
    key: [*]const u8,
    iv: [*]const u8,
    input: [*]const u8,
    input_len: u64,
    out_result: *c.ZigLeanCipherResult,
) u32 {
    const in_slice = input[0..@intCast(input_len)];
    const padded_len = (in_slice.len + blk - 1) / blk * blk;
    const padded = std.heap.c_allocator.alloc(u8, padded_len) catch return setError(out_result, STATUS_ALLOC);
    @memcpy(padded[0..in_slice.len], in_slice);
    const pad = @as(u8, @intCast(padded_len - in_slice.len));
    var pi: usize = in_slice.len;
    while (pi < padded_len) : (pi += 1) {
        padded[pi] = pad;
    }
    const out = std.heap.c_allocator.alloc(u8, padded_len) catch {
        std.heap.c_allocator.free(padded);
        return setError(out_result, STATUS_ALLOC);
    };
    const enc = Aes.Aes256.initEnc(key[0..key_len].*);
    var prev: [blk]u8 = iv[0..blk].*;
    var i: usize = 0;
    while (i < padded_len) : (i += blk) {
        var block: [blk]u8 = undefined;
        for (0..blk) |j| {
            block[j] = padded[i + j] ^ prev[j];
        }
        var enc_block: [blk]u8 = undefined;
        enc.encrypt(&enc_block, &block);
        @memcpy(out[i..][0..blk], &enc_block);
        prev = enc_block;
    }
    std.heap.c_allocator.free(padded);
    return setSuccess(out_result, out);
}

export fn ziglean_crypto_aes256_cbc_decrypt(
    key: [*]const u8,
    iv: [*]const u8,
    input: [*]const u8,
    input_len: u64,
    out_result: *c.ZigLeanCipherResult,
) u32 {
    if (input_len == 0 or input_len % blk != 0) return setError(out_result, STATUS_INVALID);
    const in_slice = input[0..@intCast(input_len)];
    const out = std.heap.c_allocator.alloc(u8, in_slice.len) catch return setError(out_result, STATUS_ALLOC);
    const dec = Aes.Aes256.initDec(key[0..key_len].*);
    var prev: [blk]u8 = iv[0..blk].*;
    var i: usize = 0;
    while (i < in_slice.len) : (i += blk) {
        const enc_block: [blk]u8 = in_slice[i..][0..blk].*;
        var dec_block: [blk]u8 = undefined;
        dec.decrypt(&dec_block, &enc_block);
        var plain: [blk]u8 = undefined;
        for (0..blk) |j| {
            plain[j] = dec_block[j] ^ prev[j];
        }
        @memcpy(out[i..][0..blk], &plain);
        prev = enc_block;
    }
    // Strip PKCS#7 padding.
    const pad = out[out.len - 1];
    if (pad == 0 or pad > blk) {
        std.heap.c_allocator.free(out);
        return setError(out_result, STATUS_INVALID);
    }
    const unpadded_len = out.len - pad;
    const final_buf = std.heap.c_allocator.alloc(u8, unpadded_len) catch {
        std.heap.c_allocator.free(out);
        return setError(out_result, STATUS_ALLOC);
    };
    @memcpy(final_buf, out[0..unpadded_len]);
    std.heap.c_allocator.free(out);
    return setSuccess(out_result, final_buf);
}

export fn ziglean_crypto_cipher_free(ptr: ?[*]u8, len: u64) void {
    if (ptr) |p| {
        std.heap.c_allocator.free(p[0..@intCast(len)]);
    }
}
