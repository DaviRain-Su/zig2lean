# Zig-backed Lean Crypto Hash Blake2s-256 Extension Design

## Goal

Extend `ZigLean.Crypto.Hash` with Blake2s-256.

## Scope

Add one-shot Blake2s-256 API:

- `blake2s256 : ByteArray -> IO ByteArray`

## Architecture

Same pattern as Blake2b-256:

```text
Lean API
  ↓ @[extern]
C shim
  ↓
Zig C ABI
  ↓
std.crypto.hash.blake2.Blake2s256
```

## Public Lean API

```lean
def blake2s256 (input : ByteArray) : IO ByteArray
```

## C ABI Boundary

```c
#define ZIGLEAN_CRYPTO_BLAKE2S256_LEN 32

uint32_t ziglean_crypto_blake2s256(
  const uint8_t* input,
  uint64_t input_len,
  uint8_t* out_digest
);
```

## Zig Implementation

Use Zig 0.16 `std.crypto.hash.blake2.Blake2s256.hash`.

## Testing

Add Blake2s-256 cases to `CryptoHashTest.lean`:

- Empty input digest.
