const std = @import("std");
const ChaCha20 = std.crypto.stream.chacha.ChaCha20IETF;
const XChaCha20 = std.crypto.stream.chacha.XChaCha20IETF;
const ChaCha20Legacy = std.crypto.stream.chacha.ChaCha20With64BitNonce;
const c = @cImport({
    @cInclude("ziglean_crypto_stream_cipher.h");
});

const STATUS_OK: u32 = 0;
const STATUS_INVALID: u32 = 1;
const STATUS_ALLOC: u32 = 2;

fn setError(out: *c.ZigLeanStreamCipherResult, status: u32) u32 {
    out.* = .{ .status = status, .reserved = 0, .out_len = 0, .out = null };
    return status;
}

fn setSuccess(out: *c.ZigLeanStreamCipherResult, buf: []u8) u32 {
    out.* = .{ .status = STATUS_OK, .reserved = 0, .out_len = @intCast(buf.len), .out = buf.ptr };
    return STATUS_OK;
}

fn xorBytes(
    key: [*]const u8,
    nonce: [*]const u8,
    expected_nonce_len: usize,
    counter: u32,
    input: [*]const u8,
    input_len: u64,
    out_result: *c.ZigLeanStreamCipherResult,
    comptime Cipher: type,
) u32 {
    if (input_len == 0) return setError(out_result, STATUS_INVALID);
    if (expected_nonce_len != Cipher.nonce_length) return setError(out_result, STATUS_INVALID);
    const out = std.heap.c_allocator.alloc(u8, @intCast(input_len)) catch return setError(out_result, STATUS_ALLOC);
    const key_bytes: *const [Cipher.key_length]u8 = key[0..Cipher.key_length];
    const nonce_bytes: *const [Cipher.nonce_length]u8 = nonce[0..Cipher.nonce_length];
    Cipher.xor(
        out,
        input[0..@intCast(input_len)],
        counter,
        key_bytes.*,
        nonce_bytes.*,
    );
    return setSuccess(out_result, out);
}

export fn ziglean_crypto_chacha20_xor(
    key: [*]const u8,
    nonce: [*]const u8,
    counter: u32,
    input: [*]const u8,
    input_len: u64,
    out_result: *c.ZigLeanStreamCipherResult,
) u32 {
    return xorBytes(key, nonce, ChaCha20.nonce_length, counter, input, input_len, out_result, ChaCha20);
}

export fn ziglean_crypto_xchacha20_xor(
    key: [*]const u8,
    nonce: [*]const u8,
    counter: u32,
    input: [*]const u8,
    input_len: u64,
    out_result: *c.ZigLeanStreamCipherResult,
) u32 {
    return xorBytes(key, nonce, XChaCha20.nonce_length, counter, input, input_len, out_result, XChaCha20);
}

// Original ChaCha20 variant (64-bit counter, 8-byte nonce), used for
// interop with implementations that follow the pre-IETF layout.
export fn ziglean_crypto_chacha20_legacy_xor(
    key: [*]const u8,
    nonce: [*]const u8,
    counter: u64,
    input: [*]const u8,
    input_len: u64,
    out_result: *c.ZigLeanStreamCipherResult,
) u32 {
    if (input_len == 0) return setError(out_result, STATUS_INVALID);
    if (ChaCha20Legacy.nonce_length != 8) return setError(out_result, STATUS_INVALID);
    const out = std.heap.c_allocator.alloc(u8, @intCast(input_len)) catch return setError(out_result, STATUS_ALLOC);
    const key_bytes: *const [ChaCha20Legacy.key_length]u8 = key[0..ChaCha20Legacy.key_length];
    const nonce_bytes: *const [ChaCha20Legacy.nonce_length]u8 = nonce[0..ChaCha20Legacy.nonce_length];
    ChaCha20Legacy.xor(
        out,
        input[0..@intCast(input_len)],
        counter,
        key_bytes.*,
        nonce_bytes.*,
    );
    return setSuccess(out_result, out);
}

export fn ziglean_crypto_stream_cipher_free(ptr: ?[*]u8, len: u64) void {
    if (ptr) |p| {
        std.heap.c_allocator.free(p[0..@intCast(len)]);
    }
}
