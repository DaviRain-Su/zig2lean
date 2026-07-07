# Zig-backed Lean Codec Base32 Extension Design

## Goal

Extend `ZigLean.Codec` with Base32 encode/decode helpers backed by Zig standard library implementations.

## Scope

Add one-shot Base32 APIs:

- `base32Encode : ByteArray -> IO String` — standard RFC 4648 Base32 with padding.
- `base32Decode : String -> IO (Except CodecError ByteArray)` — standard RFC 4648 Base32 with padding.

## Non-goals

- No Base32hex variant in this slice.
- No streaming Base32 API.
- No Base32 URL-safe variant.

## Architecture

Same layered pattern as existing codecs:

```text
Lean API
  ↓ @[extern]
C shim
  ↓
Zig C ABI
  ↓
std.base32
```

## Public Lean API

```lean
def base32Encode (input : ByteArray) : IO String
def base32Decode (input : String) : IO (Except CodecError ByteArray)
```

## C ABI Boundary

Reuse the existing `ZigLeanCodecResult` struct and status codes.

```c
uint32_t ziglean_codec_base32_encode(const uint8_t* input, uint64_t input_len, ZigLeanCodecResult* out_result);
uint32_t ziglean_codec_base32_decode(const uint8_t* input, uint64_t input_len, ZigLeanCodecResult* out_result);
```

## Zig Implementation

Use Zig 0.16 `std.base32.standard.Encoder` / `std.base32.standard.Decoder`.

## Testing

Add Base32 cases to `CodecTest.lean`:

- Encode empty input.
- Encode/decode `"hello"`.
- Decode invalid character fails with status `2`.
- Decode invalid padding fails with status `2`.

## Extension Path

After this slice is stable, consider adding Base32hex.
