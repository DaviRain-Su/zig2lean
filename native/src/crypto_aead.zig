const std = @import("std");
const Aes256Gcm = std.crypto.aead.aes_gcm.Aes256Gcm;
const Aes256GcmSiv = std.crypto.aead.aes_gcm_siv.Aes256GcmSiv;
const Aegis256 = std.crypto.aead.aegis.Aegis256;
const ChaCha20Poly1305 = std.crypto.aead.chacha_poly.ChaCha20Poly1305;
const Aes256Ocb = std.crypto.aead.aes_ocb.Aes256Ocb;
const Aes256Siv = std.crypto.aead.aes_siv.Aes256Siv;
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

fn encryptAes256GcmSiv(
    key: [*]const u8,
    nonce: [*]const u8,
    aad: []const u8,
    plaintext: []const u8,
    out_result: *c.ZigLeanAeadResult,
) u32 {
    const out = allocBytes(plaintext.len + Aes256GcmSiv.tag_length) catch return setError(out_result, STATUS_ALLOC);
    var tag: [Aes256GcmSiv.tag_length]u8 = undefined;
    Aes256GcmSiv.encrypt(
        out[0..plaintext.len],
        &tag,
        plaintext,
        aad,
        nonce[0..Aes256GcmSiv.nonce_length].*,
        key[0..Aes256GcmSiv.key_length].*,
    );
    @memcpy(out[plaintext.len..], &tag);
    return setSuccess(out_result, out);
}

fn decryptAes256GcmSiv(
    key: [*]const u8,
    nonce: [*]const u8,
    aad: []const u8,
    ciphertext_and_tag: []const u8,
    out_result: *c.ZigLeanAeadResult,
) u32 {
    if (ciphertext_and_tag.len < Aes256GcmSiv.tag_length) return setError(out_result, STATUS_INVALID);
    const cipher_len = ciphertext_and_tag.len - Aes256GcmSiv.tag_length;
    const out = allocBytes(cipher_len) catch return setError(out_result, STATUS_ALLOC);
    const tag = ciphertext_and_tag[cipher_len..][0..Aes256GcmSiv.tag_length].*;
    Aes256GcmSiv.decrypt(
        out,
        ciphertext_and_tag[0..cipher_len],
        tag,
        aad,
        nonce[0..Aes256GcmSiv.nonce_length].*,
        key[0..Aes256GcmSiv.key_length].*,
    ) catch {
        std.heap.c_allocator.free(out);
        return setError(out_result, STATUS_AUTH);
    };
    return setSuccess(out_result, out);
}

fn encryptAegis256(
    key: [*]const u8,
    nonce: [*]const u8,
    aad: []const u8,
    plaintext: []const u8,
    out_result: *c.ZigLeanAeadResult,
) u32 {
    const out = allocBytes(plaintext.len + Aegis256.tag_length) catch return setError(out_result, STATUS_ALLOC);
    var tag: [Aegis256.tag_length]u8 = undefined;
    Aegis256.encrypt(
        out[0..plaintext.len],
        &tag,
        plaintext,
        aad,
        nonce[0..Aegis256.nonce_length].*,
        key[0..Aegis256.key_length].*,
    );
    @memcpy(out[plaintext.len..], &tag);
    return setSuccess(out_result, out);
}

fn decryptAegis256(
    key: [*]const u8,
    nonce: [*]const u8,
    aad: []const u8,
    ciphertext_and_tag: []const u8,
    out_result: *c.ZigLeanAeadResult,
) u32 {
    if (ciphertext_and_tag.len < Aegis256.tag_length) return setError(out_result, STATUS_INVALID);
    const cipher_len = ciphertext_and_tag.len - Aegis256.tag_length;
    const out = allocBytes(cipher_len) catch return setError(out_result, STATUS_ALLOC);
    const tag = ciphertext_and_tag[cipher_len..][0..Aegis256.tag_length].*;
    Aegis256.decrypt(
        out,
        ciphertext_and_tag[0..cipher_len],
        tag,
        aad,
        nonce[0..Aegis256.nonce_length].*,
        key[0..Aegis256.key_length].*,
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

export fn ziglean_crypto_aes256gcmsiv_encrypt(
    key: [*]const u8,
    nonce: [*]const u8,
    aad: [*]const u8,
    aad_len: u64,
    plaintext: [*]const u8,
    plaintext_len: u64,
    out_result: *c.ZigLeanAeadResult,
) u32 {
    return encryptAes256GcmSiv(key, nonce, aad[0..@intCast(aad_len)], plaintext[0..@intCast(plaintext_len)], out_result);
}

export fn ziglean_crypto_aes256gcmsiv_decrypt(
    key: [*]const u8,
    nonce: [*]const u8,
    aad: [*]const u8,
    aad_len: u64,
    ciphertext_and_tag: [*]const u8,
    ciphertext_and_tag_len: u64,
    out_result: *c.ZigLeanAeadResult,
) u32 {
    return decryptAes256GcmSiv(key, nonce, aad[0..@intCast(aad_len)], ciphertext_and_tag[0..@intCast(ciphertext_and_tag_len)], out_result);
}

export fn ziglean_crypto_aegis256_encrypt(
    key: [*]const u8,
    nonce: [*]const u8,
    aad: [*]const u8,
    aad_len: u64,
    plaintext: [*]const u8,
    plaintext_len: u64,
    out_result: *c.ZigLeanAeadResult,
) u32 {
    return encryptAegis256(key, nonce, aad[0..@intCast(aad_len)], plaintext[0..@intCast(plaintext_len)], out_result);
}

export fn ziglean_crypto_aegis256_decrypt(
    key: [*]const u8,
    nonce: [*]const u8,
    aad: [*]const u8,
    aad_len: u64,
    ciphertext_and_tag: [*]const u8,
    ciphertext_and_tag_len: u64,
    out_result: *c.ZigLeanAeadResult,
) u32 {
    return decryptAegis256(key, nonce, aad[0..@intCast(aad_len)], ciphertext_and_tag[0..@intCast(ciphertext_and_tag_len)], out_result);
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

fn encryptOcb(
    key: [*]const u8,
    nonce: [*]const u8,
    aad: []const u8,
    plaintext: []const u8,
    out_result: *c.ZigLeanAeadResult,
) u32 {
    const out = allocBytes(plaintext.len + Aes256Ocb.tag_length) catch return setError(out_result, STATUS_ALLOC);
    var tag: [Aes256Ocb.tag_length]u8 = undefined;
    Aes256Ocb.encrypt(
        out[0..plaintext.len],
        &tag,
        plaintext,
        aad,
        nonce[0..Aes256Ocb.nonce_length].*,
        key[0..Aes256Ocb.key_length].*,
    );
    @memcpy(out[plaintext.len..], &tag);
    return setSuccess(out_result, out);
}

fn decryptOcb(
    key: [*]const u8,
    nonce: [*]const u8,
    aad: []const u8,
    ciphertext_and_tag: []const u8,
    out_result: *c.ZigLeanAeadResult,
) u32 {
    if (ciphertext_and_tag.len < Aes256Ocb.tag_length) return setError(out_result, STATUS_INVALID);
    const cipher_len = ciphertext_and_tag.len - Aes256Ocb.tag_length;
    const out = allocBytes(cipher_len) catch return setError(out_result, STATUS_ALLOC);
    const tag = ciphertext_and_tag[cipher_len..][0..Aes256Ocb.tag_length].*;
    Aes256Ocb.decrypt(
        out,
        ciphertext_and_tag[0..cipher_len],
        tag,
        aad,
        nonce[0..Aes256Ocb.nonce_length].*,
        key[0..Aes256Ocb.key_length].*,
    ) catch {
        std.heap.c_allocator.free(out);
        return setError(out_result, STATUS_AUTH);
    };
    return setSuccess(out_result, out);
}

fn sivNonce(nonce: [*]const u8, nonce_len: u64) ?[]const u8 {
    if (nonce_len == 0) return null;
    return nonce[0..@intCast(nonce_len)];
}

fn encryptSiv(
    key: [*]const u8,
    nonce: [*]const u8,
    nonce_len: u64,
    aad: []const u8,
    plaintext: []const u8,
    out_result: *c.ZigLeanAeadResult,
) u32 {
    const out = allocBytes(plaintext.len + Aes256Siv.tag_length) catch return setError(out_result, STATUS_ALLOC);
    var tag: [Aes256Siv.tag_length]u8 = undefined;
    Aes256Siv.encrypt(
        out[0..plaintext.len],
        &tag,
        plaintext,
        aad,
        sivNonce(nonce, nonce_len),
        key[0..Aes256Siv.key_length].*,
    );
    @memcpy(out[plaintext.len..], &tag);
    return setSuccess(out_result, out);
}

fn decryptSiv(
    key: [*]const u8,
    nonce: [*]const u8,
    nonce_len: u64,
    aad: []const u8,
    ciphertext_and_tag: []const u8,
    out_result: *c.ZigLeanAeadResult,
) u32 {
    if (ciphertext_and_tag.len < Aes256Siv.tag_length) return setError(out_result, STATUS_INVALID);
    const cipher_len = ciphertext_and_tag.len - Aes256Siv.tag_length;
    const out = allocBytes(cipher_len) catch return setError(out_result, STATUS_ALLOC);
    const tag = ciphertext_and_tag[cipher_len..][0..Aes256Siv.tag_length].*;
    Aes256Siv.decrypt(
        out,
        ciphertext_and_tag[0..cipher_len],
        tag,
        aad,
        sivNonce(nonce, nonce_len),
        key[0..Aes256Siv.key_length].*,
    ) catch {
        std.heap.c_allocator.free(out);
        return setError(out_result, STATUS_AUTH);
    };
    return setSuccess(out_result, out);
}

export fn ziglean_crypto_aes256ocb_encrypt(
    key: [*]const u8,
    nonce: [*]const u8,
    aad: [*]const u8,
    aad_len: u64,
    plaintext: [*]const u8,
    plaintext_len: u64,
    out_result: *c.ZigLeanAeadResult,
) u32 {
    return encryptOcb(key, nonce, aad[0..@intCast(aad_len)], plaintext[0..@intCast(plaintext_len)], out_result);
}

export fn ziglean_crypto_aes256ocb_decrypt(
    key: [*]const u8,
    nonce: [*]const u8,
    aad: [*]const u8,
    aad_len: u64,
    ciphertext_and_tag: [*]const u8,
    ciphertext_and_tag_len: u64,
    out_result: *c.ZigLeanAeadResult,
) u32 {
    return decryptOcb(key, nonce, aad[0..@intCast(aad_len)], ciphertext_and_tag[0..@intCast(ciphertext_and_tag_len)], out_result);
}

export fn ziglean_crypto_aes256siv_encrypt(
    key: [*]const u8,
    nonce: [*]const u8,
    nonce_len: u64,
    aad: [*]const u8,
    aad_len: u64,
    plaintext: [*]const u8,
    plaintext_len: u64,
    out_result: *c.ZigLeanAeadResult,
) u32 {
    return encryptSiv(key, nonce, nonce_len, aad[0..@intCast(aad_len)], plaintext[0..@intCast(plaintext_len)], out_result);
}

export fn ziglean_crypto_aes256siv_decrypt(
    key: [*]const u8,
    nonce: [*]const u8,
    nonce_len: u64,
    aad: [*]const u8,
    aad_len: u64,
    ciphertext_and_tag: [*]const u8,
    ciphertext_and_tag_len: u64,
    out_result: *c.ZigLeanAeadResult,
) u32 {
    return decryptSiv(key, nonce, nonce_len, aad[0..@intCast(aad_len)], ciphertext_and_tag[0..@intCast(ciphertext_and_tag_len)], out_result);
}

export fn ziglean_crypto_aead_free(ptr: ?[*]u8, len: u64) void {
    if (ptr) |p| {
        std.heap.c_allocator.free(p[0..@intCast(len)]);
    }
}
