# Zig-backed Lean Random / UUID Design

## Goal

Add `ZigLean.Random` and `ZigLean.Uuid` modules that expose cryptographically secure random byte generation and RFC 4122 UUID v4 generation, backed by the Zig standard library. These provide foundational SDK utilities for key generation, nonces, identifiers, and testing fixtures.

## Scope

The MVP covers two tightly related one-shot APIs:

- `ZigLean.Random.randomBytes (n : Nat) : IO ByteArray`
- `ZigLean.Uuid.uuid4 : IO String`

`randomBytes` returns `n` bytes from the Zig CSPRNG. `uuid4` returns a canonical lowercase UUID string such as `f47ac10b-58cc-4372-a567-0e02b2c3d479`.

## Non-goals

- No deterministic / seedable PRNG in the MVP
- No UUID versions other than v4 in the MVP
- No UUID parsing or validation helpers in the MVP
- No async or streaming random generation in the MVP
- No entropy source configuration in the MVP

## Architecture

```text
Lean API
  ↓ @[extern]
Lean runtime C shim
  ↓
Zig C ABI
  ↓
std.crypto.random
```

Lean owns the public API and result types. Zig performs the random byte generation. The C shim copies native outputs into Lean-owned `ByteArray` or `String`.

## Public Lean Modules

Recommended module layout:

```text
ZigLean/
  Random.lean
  Random/
    FFI.lean
  Uuid.lean
  Uuid/
    FFI.lean
```

`ZigLean.lean` should re-export `ZigLean.Random` and `ZigLean.Uuid`.

Public API:

```lean
namespace ZigLean.Random

def randomBytes (n : Nat) : IO ByteArray

end ZigLean.Random
```

```lean
namespace ZigLean.Uuid

def uuid4 : IO String

end ZigLean.Uuid
```

## C ABI Boundary

### Random

```c
typedef struct {
  uint32_t status;
  uint32_t reserved;
  uint64_t out_len;
  uint8_t* out;
} ZigLeanRandomResult;

uint32_t ziglean_random_bytes(
  uint64_t len,
  ZigLeanRandomResult* out_result
);

void ziglean_random_free(uint8_t* ptr, uint64_t len);
```

Return code `0` means success. Nonzero statuses map to `IO.userError` in Lean.

Initial status codes:

- `1`: requested length is too large for the implementation
- `2`: allocation failure

### UUID

```c
typedef struct {
  uint32_t status;
  uint32_t reserved;
  uint64_t out_len;
  uint8_t* out;
} ZigLeanUuidResult;

uint32_t ziglean_uuid_v4(
  ZigLeanUuidResult* out_result
);

void ziglean_uuid_free(uint8_t* ptr, uint64_t len);
```

Return code `0` means success. Nonzero statuses map to `IO.userError` in Lean.

Initial status codes:

- `1`: allocation failure

The output string is a 36-byte ASCII representation of the UUID, including hyphens.

## Zig Implementation

Use Zig 0.16 APIs:

- Random bytes: a small `fillRandom` helper that uses `std.c.getrandom` on Linux and `std.c.arc4random_buf` on macOS/BSD. This is necessary because Zig 0.16.0 does not expose `std.crypto.random.bytes`.
- UUID v4: fill 16 bytes with that helper, then set bits:
  - `bytes[6] = (bytes[6] & 0x0F) | 0x40` (version = 4)
  - `bytes[8] = (bytes[8] & 0x3F) | 0x80` (variant = 10)
  - Format as `xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx` where `y` is `(bytes[8] & 0x3F) | 0x80` rendered in hex.

Zig owns output buffers allocated with `std.heap.c_allocator`; the C shim must copy output into Lean-owned objects and call `ziglean_random_free` / `ziglean_uuid_free` exactly once.

## Error Handling

`randomBytes` and `uuid4` are total except for allocation failure. The Lean API returns `IO ByteArray` / `IO String`; native allocation failure should become `IO.userError`.

## Build Integration

Extend the existing native static library:

```text
native/
  src/root.zig
  src/random.zig
  src/uuid.zig
  c/lean_random.c
  c/lean_uuid.c
  include/ziglean_random.h
  include/ziglean_uuid.h
```

`native/src/root.zig` should import `random.zig` and `uuid.zig`. `native/build.zig` should compile `lean_random.c` and `lean_uuid.c`. `lakefile.lean` should track all new native files as extern library dependencies.

## Testing

Add `RandomTest.lean` and `UuidTest.lean` test executables.

### Random tests

- `randomBytes 0` returns empty `ByteArray`
- `randomBytes 16` returns 16 bytes
- `randomBytes 32` returns 32 bytes
- Two successive calls produce different outputs with overwhelming probability

### UUID tests

- `uuid4` returns a 36-character string
- The string matches the regex `^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$`
- Two successive calls produce different UUIDs with overwhelming probability

## Extension Path

After this module is stable:

1. Add seedable PRNG variants for deterministic testing
2. Add UUID parsing and validation helpers
3. Add UUID v1/v7 variants if needed for database identifiers
4. Add base32 and base58 encoding helpers in `Codec`
