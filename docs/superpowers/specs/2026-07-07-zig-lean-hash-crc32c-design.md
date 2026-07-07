# Zig-backed Lean Hash CRC32C Extension Design

## Goal

Extend `ZigLean.Hash.Checksum` with CRC32C (Castagnoli / iSCSI).

## Scope

Add one-shot CRC32C API:

- `crc32c : ByteArray -> IO UInt32`

## Architecture

Same pattern as existing `crc32`:

```text
Lean API
  ↓ @[extern]
C shim
  ↓
Zig C ABI
  ↓
std.hash.crc.Crc32Iscsi
```

## Public Lean API

```lean
def crc32c (input : ByteArray) : IO UInt32
```

## C ABI Boundary

```c
uint32_t ziglean_hash_crc32c(const uint8_t* input, uint64_t input_len, uint32_t* out_crc);
```

## Zig Implementation

Use Zig 0.16 `std.hash.crc.Crc32Iscsi`.

## Testing

Add CRC32C cases to `CryptoExtendedTest.lean`:

- `crc32c "123456789"` returns `0xe3069283`.
