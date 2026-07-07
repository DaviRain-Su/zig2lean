const std = @import("std");

export fn ziglean_crypto_sha256(input: [*]const u8, input_len: u64, out_digest: [*]u8) u32 {
    const bytes = input[0..@intCast(input_len)];
    const out: *[32]u8 = @ptrCast(out_digest);
    std.crypto.hash.sha2.Sha256.hash(bytes, out, .{});
    return 0;
}

export fn ziglean_crypto_blake3(input: [*]const u8, input_len: u64, out_digest: [*]u8) u32 {
    const bytes = input[0..@intCast(input_len)];
    const out = out_digest[0..32];
    std.crypto.hash.Blake3.hash(bytes, out, .{});
    return 0;
}

export fn ziglean_crypto_blake2b256(input: [*]const u8, input_len: u64, out_digest: [*]u8) u32 {
    const bytes = input[0..@intCast(input_len)];
    const out = out_digest[0..32];
    std.crypto.hash.blake2.Blake2b256.hash(bytes, out, .{});
    return 0;
}

export fn ziglean_crypto_blake2s256(input: [*]const u8, input_len: u64, out_digest: [*]u8) u32 {
    const bytes = input[0..@intCast(input_len)];
    const out = out_digest[0..32];
    std.crypto.hash.blake2.Blake2s256.hash(bytes, out, .{});
    return 0;
}

export fn ziglean_crypto_blake2b512(input: [*]const u8, input_len: u64, out_digest: [*]u8) u32 {
    const bytes = input[0..@intCast(input_len)];
    const out = out_digest[0..64];
    std.crypto.hash.blake2.Blake2b512.hash(bytes, out, .{});
    return 0;
}

export fn ziglean_crypto_hmac_sha256(
    key: [*]const u8,
    key_len: u64,
    message: [*]const u8,
    message_len: u64,
    out_mac: [*]u8,
) u32 {
    const key_bytes = key[0..@intCast(key_len)];
    const message_bytes = message[0..@intCast(message_len)];
    const out: *[32]u8 = @ptrCast(out_mac);
    std.crypto.auth.hmac.sha2.HmacSha256.create(out, message_bytes, key_bytes);
    return 0;
}

export fn ziglean_crypto_hmac_sha512(
    key: [*]const u8,
    key_len: u64,
    message: [*]const u8,
    message_len: u64,
    out_mac: [*]u8,
) u32 {
    const key_bytes = key[0..@intCast(key_len)];
    const message_bytes = message[0..@intCast(message_len)];
    const out: *[64]u8 = @ptrCast(out_mac);
    std.crypto.auth.hmac.sha2.HmacSha512.create(out, message_bytes, key_bytes);
    return 0;
}

export fn ziglean_crypto_sha512(input: [*]const u8, input_len: u64, out_digest: [*]u8) u32 {
    const bytes = input[0..@intCast(input_len)];
    const out: *[64]u8 = @ptrCast(out_digest);
    std.crypto.hash.sha2.Sha512.hash(bytes, out, .{});
    return 0;
}

export fn ziglean_crypto_sha3_256(input: [*]const u8, input_len: u64, out_digest: [*]u8) u32 {
    const bytes = input[0..@intCast(input_len)];
    const out: *[32]u8 = @ptrCast(out_digest);
    std.crypto.hash.sha3.Sha3_256.hash(bytes, out, .{});
    return 0;
}

export fn ziglean_crypto_keccak256(input: [*]const u8, input_len: u64, out_digest: [*]u8) u32 {
    const bytes = input[0..@intCast(input_len)];
    const out: *[32]u8 = @ptrCast(out_digest);
    std.crypto.hash.sha3.Keccak256.hash(bytes, out, .{});
    return 0;
}
