const std = @import("std");
const X25519 = std.crypto.dh.X25519;

export fn ziglean_crypto_x25519_keypair(
    seed: [*]const u8,
    out_keypair: [*]u8,
) u32 {
    const seed_bytes: *const [32]u8 = seed[0..32];
    const kp = X25519.KeyPair.generateDeterministic(seed_bytes.*) catch return 1;
    @memcpy(out_keypair[0..32], &kp.secret_key);
    @memcpy(out_keypair[32..64], &kp.public_key);
    return 0;
}

export fn ziglean_crypto_x25519_shared_secret(
    secret_key: [*]const u8,
    public_key: [*]const u8,
    out_shared_secret: [*]u8,
) u32 {
    const sk: *const [32]u8 = secret_key[0..32];
    const pk: *const [32]u8 = public_key[0..32];
    const shared = X25519.scalarmult(sk.*, pk.*) catch return 1;
    @memcpy(out_shared_secret[0..32], &shared);
    return 0;
}
