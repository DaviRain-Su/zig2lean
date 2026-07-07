# Zig-backed Lean Crypto Hash HMAC-SHA512 Extension Design

## Goal

Extend `ZigLean.Crypto.Hash` with HMAC-SHA512.

## Scope

Add one-shot HMAC-SHA512 API:

- `hmacSha512 : ByteArray -> ByteArray -> IO ByteArray`

## Architecture

Same pattern as existing HMAC-SHA256:

```text
Lean API
  ↓ @[extern]
C shim
  ↓
Zig C ABI
  ↓
std.crypto.auth.hmac.sha2.HmacSha512
```

## Public Lean API

```lean
def hmacSha512 (key message : ByteArray) : IO ByteArray
```

## C ABI Boundary

```c
#define ZIGLEAN_CRYPTO_HMAC_SHA512_LEN 64

uint32_t ziglean_crypto_hmac_sha512(
  const uint8_t* key,
  uint64_t key_len,
  const uint8_t* message,
  uint64_t message_len,
  uint8_t* out_mac
);
```

## Zig Implementation

Use Zig 0.16 `std.crypto.auth.hmac.sha2.HmacSha512.create`.

## Testing

Add HMAC-SHA512 cases to `CryptoHashTest.lean`:

- Empty key/message produces known digest.
- RFC 4231 test vector for `"Hi There"` with key `0x0b * 20`.
