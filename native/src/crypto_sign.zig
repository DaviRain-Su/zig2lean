const std = @import("std");
const Ed25519 = std.crypto.sign.Ed25519;
const EcdsaSecp256k1 = std.crypto.sign.ecdsa.EcdsaSecp256k1Sha256;
const c = @cImport({
    @cInclude("ziglean_crypto_sign.h");
});

const STATUS_OK: u32 = 0;
const STATUS_INVALID: u32 = 1;

export fn ziglean_crypto_ed25519_sign(
    seed: [*]const u8,
    message: [*]const u8,
    message_len: u64,
    out_signature: [*]u8,
) u32 {
    if (seed[0..32].len != 32) return STATUS_INVALID;
    const seed_bytes: *const [32]u8 = seed[0..32];
    const kp = Ed25519.KeyPair.generateDeterministic(seed_bytes.*) catch return STATUS_INVALID;
    const sig = kp.sign(message[0..@intCast(message_len)], null) catch return STATUS_INVALID;
    const encoded = sig.toBytes();
    @memcpy(out_signature[0..64], &encoded);
    return STATUS_OK;
}

export fn ziglean_crypto_ed25519_verify(
    public_key: [*]const u8,
    message: [*]const u8,
    message_len: u64,
    signature: [*]const u8,
    out_valid: *u32,
) u32 {
    const pk = Ed25519.PublicKey.fromBytes(public_key[0..32].*) catch {
        out_valid.* = 0;
        return STATUS_OK;
    };
    const sig = Ed25519.Signature.fromBytes(signature[0..64].*);
    Ed25519.Signature.verify(sig, message[0..@intCast(message_len)], pk) catch {
        out_valid.* = 0;
        return STATUS_OK;
    };
    out_valid.* = 1;
    return STATUS_OK;
}

export fn ziglean_crypto_secp256k1_sign(
    secret_key: [*]const u8,
    message: [*]const u8,
    message_len: u64,
    out_signature: [*]u8,
) u32 {
    const sk = EcdsaSecp256k1.SecretKey.fromBytes(secret_key[0..32].*) catch return STATUS_INVALID;
    const kp = EcdsaSecp256k1.KeyPair.fromSecretKey(sk) catch return STATUS_INVALID;
    const sig = kp.sign(message[0..@intCast(message_len)], null) catch return STATUS_INVALID;
    const encoded = sig.toBytes();
    @memcpy(out_signature[0..64], &encoded);
    return STATUS_OK;
}

export fn ziglean_crypto_secp256k1_verify(
    public_key: [*]const u8,
    public_key_len: u64,
    message: [*]const u8,
    message_len: u64,
    signature: [*]const u8,
    out_valid: *u32,
) u32 {
    const pk = EcdsaSecp256k1.PublicKey.fromSec1(public_key[0..@intCast(public_key_len)]) catch {
        out_valid.* = 0;
        return STATUS_OK;
    };
    const sig = EcdsaSecp256k1.Signature.fromBytes(signature[0..64].*);
    EcdsaSecp256k1.Signature.verify(sig, message[0..@intCast(message_len)], pk) catch {
        out_valid.* = 0;
        return STATUS_OK;
    };
    out_valid.* = 1;
    return STATUS_OK;
}