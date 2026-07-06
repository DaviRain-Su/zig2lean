# Zig-backed Lean Crypto Hash Design

## Goal

Add a `ZigLean.Crypto.Hash` module that exposes selected Zig `std.crypto` hash primitives to Lean through the same native extension pattern used by the JSON module. The first crypto scope covers SHA-256, BLAKE3, and HMAC-SHA256.

## First Scope

The MVP exposes one-shot hashing and MAC helpers:

- `sha256 : ByteArray -> IO ByteArray`
- `blake3 : ByteArray -> IO ByteArray`
- `hmacSha256 : ByteArray -> ByteArray -> IO ByteArray`

`hmacSha256 key message` returns a 32-byte MAC. `sha256` and `blake3` return 32-byte digests.

## Non-goals

- No streaming hash context in the MVP
- No keyed BLAKE3 in the MVP
- No random number API in the MVP
- No signature, KDF, password hashing, or AEAD API in the MVP
- No exposure of Zig hash state, allocator state, or internal structs to Lean

## Architecture

```text
Lean API
  ↓ @[extern]
Lean runtime C shim
  ↓
Zig C ABI
  ↓
std.crypto.hash.sha2.Sha256
std.crypto.hash.Blake3
std.crypto.auth.hmac.sha2.HmacSha256
```

Lean owns the public API and receives normal `ByteArray` values. The C shim reads Lean `ByteArray` inputs, calls Zig exported functions, copies the fixed-size digest into a Lean-owned `ByteArray`, and returns it through `IO`.

## Public Lean Modules

Recommended module layout:

```text
ZigLean/
  Crypto.lean
  Crypto/
    Hash.lean
    Hash/
      FFI.lean
```

`ZigLean.lean` should re-export `ZigLean.Crypto` in addition to the existing JSON module.

The public API should live in `ZigLean.Crypto.Hash`:

```lean
namespace ZigLean.Crypto.Hash

def sha256 (input : ByteArray) : IO ByteArray
def blake3 (input : ByteArray) : IO ByteArray
def hmacSha256 (key message : ByteArray) : IO ByteArray

end ZigLean.Crypto.Hash
```

## C ABI Boundary

The Zig-facing C ABI should use caller-provided fixed output buffers instead of Zig allocation because all outputs are fixed-size 32-byte digests.

```c
#define ZIGLEAN_CRYPTO_SHA256_LEN 32
#define ZIGLEAN_CRYPTO_BLAKE3_LEN 32
#define ZIGLEAN_CRYPTO_HMAC_SHA256_LEN 32

uint32_t ziglean_crypto_sha256(
  const uint8_t* input,
  uint64_t input_len,
  uint8_t* out_digest
);

uint32_t ziglean_crypto_blake3(
  const uint8_t* input,
  uint64_t input_len,
  uint8_t* out_digest
);

uint32_t ziglean_crypto_hmac_sha256(
  const uint8_t* key,
  uint64_t key_len,
  const uint8_t* message,
  uint64_t message_len,
  uint8_t* out_mac
);
```

Return code `0` means success. Nonzero codes are reserved for future error states. The MVP implementations are expected to be infallible for valid byte pointers and lengths.

## Lean Runtime C Shim

The C shim should export Lean-callable functions:

```c
lean_obj_res lean_ziglean_crypto_sha256(b_lean_obj_arg input, lean_obj_arg world);
lean_obj_res lean_ziglean_crypto_blake3(b_lean_obj_arg input, lean_obj_arg world);
lean_obj_res lean_ziglean_crypto_hmac_sha256(
  b_lean_obj_arg key,
  b_lean_obj_arg message,
  lean_obj_arg world
);
```

Each function allocates a 32-byte Lean `ByteArray`, calls the corresponding Zig function into that buffer, and returns the `ByteArray` in an `IO` result.

## Zig Implementation

The Zig implementation should use Zig 0.16 APIs:

```zig
std.crypto.hash.sha2.Sha256.hash(input, out, .{});
std.crypto.hash.Blake3.hash(input, out, .{});
std.crypto.auth.hmac.sha2.HmacSha256.create(out, message, key);
```

If the exact Zig 0.16 namespace differs, the implementation should follow the installed standard library source while preserving the C ABI above.

## Error Handling

The Lean public API can return `IO ByteArray` rather than `Except` because the selected functions are deterministic, total over byte arrays, and have fixed output sizes.

If Zig returns a nonzero status, the C shim should return an `IO.userError` rather than silently returning a digest. This keeps the public Lean API simple while still preserving native error visibility.

## Build Integration

Extend the existing native static library instead of creating a second library:

```text
native/
  src/json.zig
  src/crypto_hash.zig
  c/lean_json.c
  c/lean_crypto_hash.c
  include/ziglean_json.h
  include/ziglean_crypto_hash.h
```

`native/build.zig` should compile both Zig source files and both C shim files into the existing `liblean_ziglean` artifact. `lakefile.lean` should include the new native inputs as dependencies of the existing `extern_lib`.

## Testing

Add a dedicated test executable or extend the current test executable with crypto assertions. The MVP test vectors should cover:

- SHA-256 empty input
- SHA-256 `"abc"`
- BLAKE3 empty input
- BLAKE3 `"abc"`
- HMAC-SHA256 with RFC 4231 test case 1
- repeated calls to ensure no stale output buffer reuse
- digest lengths are exactly 32 bytes

Tests should assert exact byte output through hex encoding helper functions in Lean.

## Extension Path

After the one-shot hash API is stable, add follow-up modules in this order:

1. Base encoding helpers: hex, base64, base64url
2. Compression codecs: gzip/zlib/deflate where stable in Zig std
3. Streaming hash handles with explicit `init/update/final/free`
4. KDFs: HKDF, PBKDF2, scrypt, Argon2
5. Signature and key utilities
6. Async or I/O-backed helpers only after the FFI ownership model for handles is settled

Async APIs should not be mixed into this crypto hash MVP because they need a different lifetime and scheduling model than fixed-size pure computations.
