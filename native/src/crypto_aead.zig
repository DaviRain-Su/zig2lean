const std = @import("std");
const Aes256Gcm = std.crypto.aead.aes_gcm.Aes256Gcm;
const ChaCha20Poly1305 = std.crypto.aead.chacha_poly.ChaCha20Poly1305;
const c = @cImport({
    @cInclude("ziglean_crypto_aead.h");
});

const STATUS_OK: u32 = 0;
const STATUS_INVALID: u32 = 1;
const STATUS_AUTH: u32 = 2;
const STATUS_ALLOC: u32 = 3;

fn setError(out: *c.ZigLeanAeadResult, status: u32) u32 {
    out.* = .{ .status = status, .reserved = 0, .out_len = 0, .error_offset = 0, .out = null };
    return status;
}

fn setSuccess(out: *c.ZigLeanAeadResult, buf: []u8) u32 {
    out.* = .{ .status = STATUS_OK, .reserved = 0, .out_len = @intCast(buf.len), .error_offset = 0, .out = buf.ptr };
    return STATUS_OK;
}

fn allocBytes(len: usize) ![]u8 {
    return std.heap.c_allocator.alloc(u8, len);
}

fn encryptAes256Gcm(
    key: [*]const u8,
    nonce: [*]const u8,
    aad: []const u8,
    plaintext: []const u8,
    out_result: *c.ZigLeanAeadResult,
) u32 {
    const out = allocBytes(plaintext.len + Aes256Gcm.tag_length) catch return setError(out_result, STATUS_ALLOC);
    var tag: [Aes256Gcm.tag_length]u8 = undefined;
    Aes256Gcm.encrypt(
        out[0..plaintext.len],
        &tag,
        plaintext,
        aad,
        nonce[0..Aes256Gcm.nonce_length].*,
        key[0..Aes256Gcm.key_length].*,
    );
    @memcpy(out[plaintext.len..], &tag);
    return setSuccess(out_result, out);
}

fn decryptAes256Gcm(
    key: [*]const u8,
    nonce: [*]const u8,
    aad: []const u8,
    ciphertext_and_tag: []const u8,
    out_result: *c.ZigLeanAeadResult,
) u32 {
    if (ciphertext_and_tag.len < Aes256Gcm.tag_length) return setError(out_result, STATUS_INVALID);
    const cipher_len = ciphertext_and_tag.len - Aes256Gcm.tag_length;
    const out = allocBytes(cipher_len) catch return setError(out_result, STATUS_ALLOC);
    const tag = ciphertext_and_tag[cipher_len..][0..Aes256Gcm.tag_length].*;
    Aes256Gcm.decrypt(
        out,
        ciphertext_and_tag[0..cipher_len],
        tag,
        aad,
        nonce[0..Aes256Gcm.nonce_length].*,
        key[0..Aes256Gcm.key_length].*,
    ) catch {
        std.heap.c_allocator.free(out);
        return setError(out_result, STATUS_AUTH);
    };
    return setSuccess(out_result, out);
}

fn encryptChaCha(
    key: [*]const u8,
    nonce: [*]const u8,
    aad: []const u8,
    plaintext: []const u8,
    out_result: *c.ZigLeanAeadResult,
) u32 {
    const out = allocBytes(plaintext.len + ChaCha20Poly1305.tag_length) catch return setError(out_result, STATUS_ALLOC);
    var tag: [ChaCha20Poly1305.tag_length]u8 = undefined;
    ChaCha20Poly1305.encrypt(
        out[0..plaintext.len],
        &tag,
        plaintext,
        aad,
        nonce[0..ChaCha20Poly1305.nonce_length].*,
        key[0..ChaCha20Poly1305.key_length].*,
    );
    @memcpy(out[plaintext.len..], &tag);
    return setSuccess(out_result, out);
}

fn decryptChaCha(
    key: [*]const u8,
    nonce: [*]const u8,
    aad: []const u8,
    ciphertext_and_tag: []const u8,
    out_result: *c.ZigLeanAeadResult,
) u32 {
    if (ciphertext_and_tag.len < ChaCha20Poly1305.tag_length) return setError(out_result, STATUS_INVALID);
    const cipher_len = ciphertext_and_tag.len - ChaCha20Poly1305.tag_length;
    const out = allocBytes(cipher_len) catch return setError(out_result, STATUS_ALLOC);
    const tag = ciphertext_and_tag[cipher_len..][0..ChaCha20Poly1305.tag_length].*;
    ChaCha20Poly1305.decrypt(
        out,
        ciphertext_and_tag[0..cipher_len],
        tag,
        aad,
        nonce[0..ChaCha20Poly1305.nonce_length].*,
        key[0..ChaCha20Poly1305.key_length].*,
    ) catch {
        std.heap.c_allocator.free(out);
        return setError(out_result, STATUS_AUTH);
    };
    return setSuccess(out_result, out);
}

export fn ziglean_crypto_aes256gcm_encrypt(
    key: [*]const u8,
    nonce: [*]const u8,
    aad: [*]const u8,
    aad_len: u64,
    plaintext: [*]const u8,
    plaintext_len: u64,
    out_result: *c.ZigLeanAeadResult,
) u32 {
    return encryptAes256Gcm(key, nonce, aad[0..@intCast(aad_len)], plaintext[0..@intCast(plaintext_len)], out_result);
}

export fn ziglean_crypto_aes256gcm_decrypt(
    key: [*]const u8,
    nonce: [*]const u8,
    aad: [*]const u8,
    aad_len: u64,
    ciphertext_and_tag: [*]const u8,
    ciphertext_and_tag_len: u64,
    out_result: *c.ZigLeanAeadResult,
) u32 {
    return decryptAes256Gcm(key, nonce, aad[0..@intCast(aad_len)], ciphertext_and_tag[0..@intCast(ciphertext_and_tag_len)], out_result);
}

export fn ziglean_crypto_chacha20poly1305_encrypt(
    key: [*]const u8,
    nonce: [*]const u8,
    aad: [*]const u8,
    aad_len: u64,
    plaintext: [*]const u8,
    plaintext_len: u64,
    out_result: *c.ZigLeanAeadResult,
) u32 {
    return encryptChaCha(key, nonce, aad[0..@intCast(aad_len)], plaintext[0..@intCast(plaintext_len)], out_result);
}

export fn ziglean_crypto_chacha20poly1305_decrypt(
    key: [*]const u8,
    nonce: [*]const u8,
    aad: [*]const u8,
    aad_len: u64,
    ciphertext_and_tag: [*]const u8,
    ciphertext_and_tag_len: u64,
    out_result: *c.ZigLeanAeadResult,
) u32 {
    return decryptChaCha(key, nonce, aad[0..@intCast(aad_len)], ciphertext_and_tag[0..@intCast(ciphertext_and_tag_len)], out_result);
}

export fn ziglean_crypto_aead_free(ptr: ?[*]u8, len: u64) void {
    if (ptr) |p| {
        std.heap.c_allocator.free(p[0..@intCast(len)]);
    }
}