# Zig-backed Lean Codec Design

## Goal

Add a `ZigLean.Codec` module that exposes stable byte encoding and decoding helpers backed by Zig standard library implementations. This module provides the SDK's foundational byte codec layer for crypto digests, transaction builders, ABI encoders, and host-side tooling.

## First Scope

The MVP covers one-shot byte codecs:

- `hexEncodeLower : ByteArray -> IO String`
- `hexDecode : String -> IO (Except CodecError ByteArray)`
- `base64Encode : ByteArray -> IO String`
- `base64Decode : String -> IO (Except CodecError ByteArray)`
- `base64UrlEncode : ByteArray -> IO String`
- `base64UrlDecode : String -> IO (Except CodecError ByteArray)`

`base64Encode` uses standard padded Base64. `base64UrlEncode` uses URL-safe Base64 without padding, matching common SDK token and web payload use.

## Non-goals

- No streaming codec API in the MVP
- No MIME Base64 line wrapping in the MVP
- No Base32/Base58 in the MVP
- No Unicode text transcoding in the MVP
- No async or I/O-backed codec API in the MVP

## Architecture

```text
Lean API
  ↓ @[extern]
Lean runtime C shim
  ↓
Zig C ABI
  ↓
std.fmt / std.base64
```

Lean owns the public API and normalizes results into `String` or `Except CodecError ByteArray`. Zig performs size calculation and byte-level encode/decode. The C shim copies native outputs into Lean-owned `ByteArray` or `String`.

## Public Lean Modules

Recommended module layout:

```text
ZigLean/
  Codec.lean
  Codec/
    FFI.lean
```

`ZigLean.lean` should re-export `ZigLean.Codec`.

Public API:

```lean
namespace ZigLean.Codec

structure CodecError where
  code : UInt32
  offset : UInt64
  message : String

def hexEncodeLower (input : ByteArray) : IO String
def hexDecode (input : String) : IO (Except CodecError ByteArray)
def base64Encode (input : ByteArray) : IO String
def base64Decode (input : String) : IO (Except CodecError ByteArray)
def base64UrlEncode (input : ByteArray) : IO String
def base64UrlDecode (input : String) : IO (Except CodecError ByteArray)

end ZigLean.Codec
```

## C ABI Boundary

Encoding output length is deterministic from input length, while decode output length is bounded by the encoded input. The C ABI should return a small result struct with status, output pointer, output length, and error offset.

```c
typedef struct {
  uint32_t status;
  uint32_t reserved;
  uint64_t out_len;
  uint64_t error_offset;
  uint8_t* out;
} ZigLeanCodecResult;

uint32_t ziglean_codec_hex_encode_lower(
  const uint8_t* input,
  uint64_t input_len,
  ZigLeanCodecResult* out_result
);

uint32_t ziglean_codec_hex_decode(
  const uint8_t* input,
  uint64_t input_len,
  ZigLeanCodecResult* out_result
);

uint32_t ziglean_codec_base64_encode(
  const uint8_t* input,
  uint64_t input_len,
  ZigLeanCodecResult* out_result
);

uint32_t ziglean_codec_base64_decode(
  const uint8_t* input,
  uint64_t input_len,
  ZigLeanCodecResult* out_result
);

uint32_t ziglean_codec_base64url_encode(
  const uint8_t* input,
  uint64_t input_len,
  ZigLeanCodecResult* out_result
);

uint32_t ziglean_codec_base64url_decode(
  const uint8_t* input,
  uint64_t input_len,
  ZigLeanCodecResult* out_result
);

void ziglean_codec_free(uint8_t* ptr, uint64_t len);
```

Return code `0` means success. Nonzero statuses map to `CodecError` in Lean.

Initial status codes:

- `1`: invalid input length
- `2`: invalid character or invalid padding
- `3`: allocation failure

`error_offset` is `0` in the MVP unless Zig exposes a precise offset cheaply.

## Zig Implementation

Use Zig 0.16 APIs:

- Hex encode: `std.fmt.bytesToHex` or equivalent formatting helper
- Hex decode: `std.fmt.hexToBytes`
- Standard Base64: `std.base64.standard.Encoder` and `std.base64.standard.Decoder`
- URL-safe Base64: `std.base64.url_safe_no_pad.Encoder` and `std.base64.url_safe_no_pad.Decoder`

Zig owns output buffers allocated with `std.heap.c_allocator`; the C shim must copy output into Lean-owned objects and call `ziglean_codec_free` exactly once.

## Error Handling

Encoding functions are total over `ByteArray` except allocation failure. The Lean API returns `IO String`; native allocation failure should become `IO.userError`.

Decoding functions may fail on malformed input, so the Lean API returns `IO (Except CodecError ByteArray)`. Tests should assert stable status codes and basic offsets, not human-readable message text.

## Build Integration

Extend the existing native static library:

```text
native/
  src/root.zig
  src/codec.zig
  c/lean_codec.c
  include/ziglean_codec.h
```

`native/src/root.zig` should import `codec.zig`. `native/build.zig` should compile `lean_codec.c`. `lakefile.lean` should track all new native files as extern library dependencies.

## Testing

Add a `codec_test` executable or extend a dedicated test file. MVP tests should cover:

- hex encode empty input
- hex encode bytes `00 ff 10`
- hex decode lowercase and uppercase
- hex decode odd-length input fails with status `1`
- hex decode invalid character fails with status `2`
- base64 encode/decode empty input
- base64 encode/decode `"hello"`
- base64 decode invalid padding fails with status `2`
- base64url encode/decode `"hello?world"`
- repeated encode/decode calls to catch stale output or ownership bugs

## Extension Path

After this module is stable:

1. Add Base58 for Solana/EVM-style host utilities, likely through a Zig ecosystem dependency or local implementation if not in `std`
2. Add compression codecs
3. Add ABI and transaction serialization helpers
4. Design async/I/O handles separately, because they require explicit lifetime and scheduler ownership semantics
