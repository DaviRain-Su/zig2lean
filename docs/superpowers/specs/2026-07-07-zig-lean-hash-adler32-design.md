# Zig-backed Lean Hash Adler32 Extension Design

## Goal

Extend `ZigLean.Hash.Checksum` with an Adler32 checksum helper backed by Zig.

## Scope

Add one-shot Adler32 API:

- `adler32 : ByteArray -> IO UInt32`

## Architecture

Same pattern as existing checksums (`crc32`, `xxHash64`):

```text
Lean API
  ↓ @[extern]
C shim
  ↓
Zig C ABI
  ↓
std.hash.Adler32
```

## Public Lean API

```lean
def adler32 (input : ByteArray) : IO UInt32
```

## C ABI Boundary

```c
uint32_t ziglean_hash_adler32(const uint8_t* input, uint64_t input_len, uint32_t* out_adler);
```

## Zig Implementation

Use Zig 0.16 `std.hash.Adler32`.

## Testing

Add Adler32 cases to `CryptoExtendedTest.lean`:

- `adler32 "123456789"` returns `0x091e01de`.
- `adler32 ""` returns `1`.
