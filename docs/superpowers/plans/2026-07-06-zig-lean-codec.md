# Zig Lean Codec Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `ZigLean.Codec` with Zig-backed hex, Base64, and Base64URL one-shot encode/decode helpers.

**Architecture:** Lean exposes `String` and `ByteArray` APIs and decodes native decode results into `Except CodecError ByteArray`. Encoding functions return Lean `String` directly from the C shim. Zig owns temporary output buffers allocated with `std.heap.c_allocator`; the C shim copies them into Lean-owned values and frees Zig memory exactly once.

**Tech Stack:** Lean 4.31.0, Lake 5.0.0, Zig 0.16.0, C ABI, Lean runtime C API, Zig `std.fmt`, Zig `std.base64`.

## Global Constraints

- MVP public API includes `hexEncodeLower : ByteArray -> IO String`, `hexDecode : String -> IO (Except CodecError ByteArray)`, `base64Encode : ByteArray -> IO String`, `base64Decode : String -> IO (Except CodecError ByteArray)`, `base64UrlEncode : ByteArray -> IO String`, and `base64UrlDecode : String -> IO (Except CodecError ByteArray)`.
- `base64Encode` uses standard padded Base64.
- `base64UrlEncode` uses URL-safe Base64 without padding.
- No streaming codec API in the MVP.
- No MIME Base64 line wrapping in the MVP.
- No Base32/Base58 in the MVP.
- No Unicode text transcoding in the MVP.
- No async or I/O-backed codec API in the MVP.
- Return code `0` means success.
- Status `1` means invalid input length, status `2` means invalid character or invalid padding, and status `3` means allocation failure.
- Zig owns output buffers allocated with `std.heap.c_allocator`; the C shim copies output into Lean-owned objects and calls `ziglean_codec_free` exactly once.
- Tests assert stable status codes and basic offsets, not human-readable message text.

---

## File Structure

- `ZigLean.lean`: re-export `ZigLean.Codec`.
- `ZigLean/Codec.lean`: public codec API, `CodecError`, and raw decode-result parser.
- `ZigLean/Codec/FFI.lean`: extern declarations.
- `native/include/ziglean_codec.h`: C ABI result struct and function declarations.
- `native/src/codec.zig`: Zig encode/decode implementation.
- `native/c/lean_codec.c`: Lean runtime C shim.
- `native/src/root.zig`: import `codec.zig`.
- `native/build.zig`: compile `lean_codec.c`.
- `lakefile.lean`: add native dependencies and `codec_test` executable.
- `test/CodecTest.lean`: TDD behavior tests.

---

### Task 1: Lean API and Failing Codec Tests

**Files:**
- Modify: `ZigLean.lean`
- Create: `ZigLean/Codec.lean`
- Create: `ZigLean/Codec/FFI.lean`
- Modify: `lakefile.lean`
- Create: `test/CodecTest.lean`

**Interfaces:**
- Produces public Lean API:
  - `ZigLean.Codec.hexEncodeLower : ByteArray -> IO String`
  - `ZigLean.Codec.hexDecode : String -> IO (Except CodecError ByteArray)`
  - `ZigLean.Codec.base64Encode : ByteArray -> IO String`
  - `ZigLean.Codec.base64Decode : String -> IO (Except CodecError ByteArray)`
  - `ZigLean.Codec.base64UrlEncode : ByteArray -> IO String`
  - `ZigLean.Codec.base64UrlDecode : String -> IO (Except CodecError ByteArray)`

- [ ] **Step 1: Add failing tests**

Create `test/CodecTest.lean`:

```lean
import ZigLean

namespace CodecTest

open ZigLean.Codec

def bytes (s : String) : ByteArray :=
  s.toUTF8

def assertEq [BEq α] [ToString α] (name : String) (actual expected : α) : IO Unit := do
  if actual != expected then
    throw <| IO.userError s!"{name}: expected {expected}, got {actual}"

def assertBytes (name : String) (actual expected : ByteArray) : IO Unit := do
  if actual != expected then
    throw <| IO.userError s!"{name}: byte arrays differ; expected size {expected.size}, got {actual.size}"

def sampleBytes : ByteArray :=
  (ByteArray.empty.push 0x00).push 0xff |>.push 0x10

def expectDecodeOk (name : String) (actual : Except CodecError ByteArray) (expected : ByteArray) : IO Unit := do
  match actual with
  | Except.ok bytes => assertBytes name bytes expected
  | Except.error err => throw <| IO.userError s!"{name}: expected decode success, got code {err.code}"

def expectDecodeError (name : String) (actual : Except CodecError ByteArray) (expectedCode : UInt32) : IO Unit := do
  match actual with
  | Except.ok bytes => throw <| IO.userError s!"{name}: expected decode error, got {bytes.size} bytes"
  | Except.error err => assertEq name err.code expectedCode

def main : IO Unit := do
  assertEq "hex encode empty" (← hexEncodeLower ByteArray.empty) ""
  assertEq "hex encode sample" (← hexEncodeLower sampleBytes) "00ff10"
  expectDecodeOk "hex decode lowercase" (← hexDecode "00ff10") sampleBytes
  expectDecodeOk "hex decode uppercase" (← hexDecode "00FF10") sampleBytes
  expectDecodeError "hex decode odd length" (← hexDecode "abc") 1
  expectDecodeError "hex decode invalid char" (← hexDecode "00xz") 2

  assertEq "base64 encode empty" (← base64Encode ByteArray.empty) ""
  assertEq "base64 encode hello" (← base64Encode (bytes "hello")) "aGVsbG8="
  expectDecodeOk "base64 decode empty" (← base64Decode "") ByteArray.empty
  expectDecodeOk "base64 decode hello" (← base64Decode "aGVsbG8=") (bytes "hello")
  expectDecodeError "base64 invalid padding" (← base64Decode "aGVsbG8") 2

  assertEq "base64url encode hello query" (← base64UrlEncode (bytes "hello?world")) "aGVsbG8_d29ybGQ"
  expectDecodeOk "base64url decode hello query" (← base64UrlDecode "aGVsbG8_d29ybGQ") (bytes "hello?world")

  for _ in [0:100] do
    assertEq "repeat hex encode" (← hexEncodeLower sampleBytes) "00ff10"
    expectDecodeOk "repeat base64 decode" (← base64Decode "aGVsbG8=") (bytes "hello")

end CodecTest
```

- [ ] **Step 2: Add public Lean modules**

Modify `ZigLean.lean`:

```lean
import ZigLean.Json
import ZigLean.Crypto
import ZigLean.Codec
```

Create `ZigLean/Codec/FFI.lean`:

```lean
namespace ZigLean.Codec.FFI

@[extern "lean_ziglean_codec_hex_encode_lower"]
opaque hexEncodeLowerRaw : @& ByteArray -> IO String

@[extern "lean_ziglean_codec_hex_decode"]
opaque hexDecodeRaw : @& String -> IO ByteArray

@[extern "lean_ziglean_codec_base64_encode"]
opaque base64EncodeRaw : @& ByteArray -> IO String

@[extern "lean_ziglean_codec_base64_decode"]
opaque base64DecodeRaw : @& String -> IO ByteArray

@[extern "lean_ziglean_codec_base64url_encode"]
opaque base64UrlEncodeRaw : @& ByteArray -> IO String

@[extern "lean_ziglean_codec_base64url_decode"]
opaque base64UrlDecodeRaw : @& String -> IO ByteArray

end ZigLean.Codec.FFI
```

Create `ZigLean/Codec.lean`:

```lean
import ZigLean.Codec.FFI

namespace ZigLean.Codec

structure CodecError where
  code : UInt32
  offset : UInt64
  message : String
deriving Repr, BEq

def readU32LE? (b : ByteArray) (off : Nat) : Option UInt32 := do
  if off + 4 > b.size then none else
  let b0 := b[off]!.toUInt32
  let b1 := b[off + 1]!.toUInt32
  let b2 := b[off + 2]!.toUInt32
  let b3 := b[off + 3]!.toUInt32
  some (b0 ||| (b1 <<< 8) ||| (b2 <<< 16) ||| (b3 <<< 24))

def readU64LE? (b : ByteArray) (off : Nat) : Option UInt64 := do
  if off + 8 > b.size then none else
  let rec loop (i factor : Nat) (acc : UInt64) : UInt64 :=
    if _h : i < 8 then
      loop (i + 1) (factor * 256) (acc + UInt64.ofNat (b[off + i]!.toNat * factor))
    else
      acc
  some (loop 0 1 0)

def decodeRawResult (b : ByteArray) : Except CodecError ByteArray := Id.run do
  let some status := readU32LE? b 0
    | return Except.error { code := 9001, offset := 0, message := "short codec result" }
  let some code := readU32LE? b 4
    | return Except.error { code := 9001, offset := 0, message := "short codec result" }
  let some offset := readU64LE? b 8
    | return Except.error { code := 9001, offset := 0, message := "short codec result" }
  if status != 0 then
    return Except.error { code, offset, message := "codec decode failed" }
  return Except.ok (b.extract 16 b.size)

def hexEncodeLower (input : ByteArray) : IO String :=
  FFI.hexEncodeLowerRaw input

def hexDecode (input : String) : IO (Except CodecError ByteArray) := do
  pure <| decodeRawResult (← FFI.hexDecodeRaw input)

def base64Encode (input : ByteArray) : IO String :=
  FFI.base64EncodeRaw input

def base64Decode (input : String) : IO (Except CodecError ByteArray) := do
  pure <| decodeRawResult (← FFI.base64DecodeRaw input)

def base64UrlEncode (input : ByteArray) : IO String :=
  FFI.base64UrlEncodeRaw input

def base64UrlDecode (input : String) : IO (Except CodecError ByteArray) := do
  pure <| decodeRawResult (← FFI.base64UrlDecodeRaw input)

end ZigLean.Codec
```

- [ ] **Step 3: Add Lake executable**

Add to `lakefile.lean`:

```lean
lean_exe codec_test where
  root := `CodecTest
  srcDir := "test"
  supportInterpreter := true
```

- [ ] **Step 4: Run RED test**

Run: `lake exe codec_test`

Expected: FAIL at link time because `lean_ziglean_codec_*` symbols are missing.

- [ ] **Step 5: Commit**

```bash
git add ZigLean.lean ZigLean/Codec.lean ZigLean/Codec/FFI.lean lakefile.lean test/CodecTest.lean
git commit -m "Add Lean codec API and tests"
```

---

### Task 2: Native Codec ABI and Implementation

**Files:**
- Create: `native/include/ziglean_codec.h`
- Create: `native/src/codec.zig`
- Create: `native/c/lean_codec.c`
- Modify: `native/src/root.zig`
- Modify: `native/build.zig`
- Modify: `lakefile.lean`

**Interfaces:**
- Consumes Lean extern names from Task 1.
- Produces Zig C ABI functions `ziglean_codec_*` and `ziglean_codec_free`.

- [ ] **Step 1: Add C ABI header**

Create `native/include/ziglean_codec.h`:

```c
#ifndef ZIGLEAN_CODEC_H
#define ZIGLEAN_CODEC_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
  uint32_t status;
  uint32_t reserved;
  uint64_t out_len;
  uint64_t error_offset;
  uint8_t* out;
} ZigLeanCodecResult;

uint32_t ziglean_codec_hex_encode_lower(const uint8_t* input, uint64_t input_len, ZigLeanCodecResult* out_result);
uint32_t ziglean_codec_hex_decode(const uint8_t* input, uint64_t input_len, ZigLeanCodecResult* out_result);
uint32_t ziglean_codec_base64_encode(const uint8_t* input, uint64_t input_len, ZigLeanCodecResult* out_result);
uint32_t ziglean_codec_base64_decode(const uint8_t* input, uint64_t input_len, ZigLeanCodecResult* out_result);
uint32_t ziglean_codec_base64url_encode(const uint8_t* input, uint64_t input_len, ZigLeanCodecResult* out_result);
uint32_t ziglean_codec_base64url_decode(const uint8_t* input, uint64_t input_len, ZigLeanCodecResult* out_result);
void ziglean_codec_free(uint8_t* ptr, uint64_t len);

#ifdef __cplusplus
}
#endif

#endif
```

- [ ] **Step 2: Add Zig codec implementation**

Create `native/src/codec.zig`:

```zig
const std = @import("std");
const c = @cImport({
    @cInclude("ziglean_codec.h");
});

const STATUS_OK: u32 = 0;
const STATUS_INVALID_LENGTH: u32 = 1;
const STATUS_INVALID_DATA: u32 = 2;
const STATUS_ALLOC: u32 = 3;

fn setError(out: *c.ZigLeanCodecResult, status: u32) u32 {
    out.* = .{ .status = status, .reserved = 0, .out_len = 0, .error_offset = 0, .out = null };
    return status;
}

fn setSuccess(out: *c.ZigLeanCodecResult, buf: []u8) u32 {
    out.* = .{ .status = STATUS_OK, .reserved = 0, .out_len = @intCast(buf.len), .error_offset = 0, .out = buf.ptr };
    return STATUS_OK;
}

fn allocBytes(len: usize) ![]u8 {
    return std.heap.c_allocator.alloc(u8, len);
}

export fn ziglean_codec_hex_encode_lower(input: [*]const u8, input_len: u64, out_result: *c.ZigLeanCodecResult) u32 {
    const bytes = input[0..@intCast(input_len)];
    const out = allocBytes(bytes.len * 2) catch return setError(out_result, STATUS_ALLOC);
    const alphabet = "0123456789abcdef";
    for (bytes, 0..) |b, i| {
        out[i * 2] = alphabet[b >> 4];
        out[i * 2 + 1] = alphabet[b & 0x0f];
    }
    return setSuccess(out_result, out);
}

export fn ziglean_codec_hex_decode(input: [*]const u8, input_len: u64, out_result: *c.ZigLeanCodecResult) u32 {
    const encoded = input[0..@intCast(input_len)];
    if (encoded.len % 2 != 0) return setError(out_result, STATUS_INVALID_LENGTH);
    const out = allocBytes(encoded.len / 2) catch return setError(out_result, STATUS_ALLOC);
    _ = std.fmt.hexToBytes(out, encoded) catch |err| {
        std.heap.c_allocator.free(out);
        return switch (err) {
            error.InvalidLength => setError(out_result, STATUS_INVALID_LENGTH),
            else => setError(out_result, STATUS_INVALID_DATA),
        };
    };
    return setSuccess(out_result, out);
}

fn encodeBase64(input: []const u8, out_result: *c.ZigLeanCodecResult, comptime url_safe: bool) u32 {
    const encoder = if (url_safe) std.base64.url_safe_no_pad.Encoder else std.base64.standard.Encoder;
    const out_len = encoder.calcSize(input.len);
    const out = allocBytes(out_len) catch return setError(out_result, STATUS_ALLOC);
    _ = encoder.encode(out, input);
    return setSuccess(out_result, out);
}

fn decodeBase64(input: []const u8, out_result: *c.ZigLeanCodecResult, comptime url_safe: bool) u32 {
    const decoder = if (url_safe) std.base64.url_safe_no_pad.Decoder else std.base64.standard.Decoder;
    const out_len = decoder.calcSizeForSlice(input) catch return setError(out_result, STATUS_INVALID_DATA);
    const out = allocBytes(out_len) catch return setError(out_result, STATUS_ALLOC);
    decoder.decode(out, input) catch |err| {
        std.heap.c_allocator.free(out);
        return switch (err) {
            error.InvalidPadding, error.InvalidCharacter => setError(out_result, STATUS_INVALID_DATA),
        };
    };
    return setSuccess(out_result, out);
}

export fn ziglean_codec_base64_encode(input: [*]const u8, input_len: u64, out_result: *c.ZigLeanCodecResult) u32 {
    return encodeBase64(input[0..@intCast(input_len)], out_result, false);
}

export fn ziglean_codec_base64_decode(input: [*]const u8, input_len: u64, out_result: *c.ZigLeanCodecResult) u32 {
    return decodeBase64(input[0..@intCast(input_len)], out_result, false);
}

export fn ziglean_codec_base64url_encode(input: [*]const u8, input_len: u64, out_result: *c.ZigLeanCodecResult) u32 {
    return encodeBase64(input[0..@intCast(input_len)], out_result, true);
}

export fn ziglean_codec_base64url_decode(input: [*]const u8, input_len: u64, out_result: *c.ZigLeanCodecResult) u32 {
    return decodeBase64(input[0..@intCast(input_len)], out_result, true);
}

export fn ziglean_codec_free(ptr: ?[*]u8, len: u64) void {
    if (ptr) |p| {
        std.heap.c_allocator.free(p[0..@intCast(len)]);
    }
}
```

- [ ] **Step 3: Add C shim**

Create `native/c/lean_codec.c`:

```c
#include <lean/lean.h>
#include <stdint.h>
#include <string.h>
#include "ziglean_codec.h"

static void write_u32(uint8_t* dst, uint32_t value) {
  dst[0] = (uint8_t)(value & 0xffu);
  dst[1] = (uint8_t)((value >> 8) & 0xffu);
  dst[2] = (uint8_t)((value >> 16) & 0xffu);
  dst[3] = (uint8_t)((value >> 24) & 0xffu);
}

static void write_u64(uint8_t* dst, uint64_t value) {
  for (uint32_t i = 0; i < 8; i++) {
    dst[i] = (uint8_t)((value >> (8u * i)) & 0xffu);
  }
}

static lean_obj_res mk_codec_error(const char* message) {
  lean_object* str = lean_mk_string(message);
  lean_object* err = lean_mk_io_user_error(str);
  return lean_io_result_mk_error(err);
}

static lean_obj_res copy_result_bytes(ZigLeanCodecResult* result) {
  size_t out_len = 16u + (result->status == 0 ? (size_t)result->out_len : 0u);
  lean_object* out = lean_alloc_sarray(1, out_len, out_len);
  uint8_t* dst = lean_sarray_cptr(out);
  write_u32(dst, result->status);
  write_u32(dst + 4, result->status);
  write_u64(dst + 8, result->error_offset);
  if (result->status == 0 && result->out_len > 0) {
    memcpy(dst + 16, result->out, (size_t)result->out_len);
  }
  ziglean_codec_free(result->out, result->out_len);
  return lean_io_result_mk_ok(out);
}

static lean_obj_res copy_result_string(ZigLeanCodecResult* result, const char* message) {
  if (result->status != 0) {
    ziglean_codec_free(result->out, result->out_len);
    return mk_codec_error(message);
  }
  lean_object* out = lean_mk_string_from_bytes((const char*)result->out, (size_t)result->out_len);
  ziglean_codec_free(result->out, result->out_len);
  return lean_io_result_mk_ok(out);
}

lean_obj_res lean_ziglean_codec_hex_encode_lower(b_lean_obj_arg input, lean_obj_arg world) {
  (void)world;
  ZigLeanCodecResult result = {0, 0, 0, 0, 0};
  uint32_t status = ziglean_codec_hex_encode_lower(
    lean_sarray_cptr((lean_object*)input),
    (uint64_t)lean_sarray_size(input),
    &result
  );
  (void)status;
  return copy_result_string(&result, "hex encode failed");
}

lean_obj_res lean_ziglean_codec_hex_decode(b_lean_obj_arg input, lean_obj_arg world) {
  (void)world;
  ZigLeanCodecResult result = {0, 0, 0, 0, 0};
  size_t len = lean_string_size(input) - 1u;
  (void)ziglean_codec_hex_decode((const uint8_t*)lean_string_cstr(input), (uint64_t)len, &result);
  return copy_result_bytes(&result);
}

lean_obj_res lean_ziglean_codec_base64_encode(b_lean_obj_arg input, lean_obj_arg world) {
  (void)world;
  ZigLeanCodecResult result = {0, 0, 0, 0, 0};
  (void)ziglean_codec_base64_encode(
    lean_sarray_cptr((lean_object*)input),
    (uint64_t)lean_sarray_size(input),
    &result
  );
  return copy_result_string(&result, "base64 encode failed");
}

lean_obj_res lean_ziglean_codec_base64_decode(b_lean_obj_arg input, lean_obj_arg world) {
  (void)world;
  ZigLeanCodecResult result = {0, 0, 0, 0, 0};
  size_t len = lean_string_size(input) - 1u;
  (void)ziglean_codec_base64_decode((const uint8_t*)lean_string_cstr(input), (uint64_t)len, &result);
  return copy_result_bytes(&result);
}

lean_obj_res lean_ziglean_codec_base64url_encode(b_lean_obj_arg input, lean_obj_arg world) {
  (void)world;
  ZigLeanCodecResult result = {0, 0, 0, 0, 0};
  (void)ziglean_codec_base64url_encode(
    lean_sarray_cptr((lean_object*)input),
    (uint64_t)lean_sarray_size(input),
    &result
  );
  return copy_result_string(&result, "base64url encode failed");
}

lean_obj_res lean_ziglean_codec_base64url_decode(b_lean_obj_arg input, lean_obj_arg world) {
  (void)world;
  ZigLeanCodecResult result = {0, 0, 0, 0, 0};
  size_t len = lean_string_size(input) - 1u;
  (void)ziglean_codec_base64url_decode((const uint8_t*)lean_string_cstr(input), (uint64_t)len, &result);
  return copy_result_bytes(&result);
}
```

- [ ] **Step 4: Update native build and Lake dependencies**

Modify `native/src/root.zig`:

```zig
comptime {
    _ = @import("json.zig");
    _ = @import("crypto_hash.zig");
    _ = @import("codec.zig");
}
```

In `native/build.zig`, add:

```zig
lib.root_module.addCSourceFile(.{
    .file = b.path("c/lean_codec.c"),
    .flags = &.{ "-std=c11", "-fno-sanitize=undefined" },
});
```

In `lakefile.lean`, add input-file dependencies for:

```lean
pkg.dir / "native" / "src" / "codec.zig"
pkg.dir / "native" / "c" / "lean_codec.c"
pkg.dir / "native" / "include" / "ziglean_codec.h"
```

and include them in `depJob`.

- [ ] **Step 5: Run codec tests**

Run: `lake exe codec_test`

Expected: PASS.

- [ ] **Step 6: Run regression tests**

Run:

```bash
lake exe json_test
lake exe crypto_hash_test
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add native/include/ziglean_codec.h native/src/codec.zig native/c/lean_codec.c native/src/root.zig native/build.zig lakefile.lean
git commit -m "Implement Zig codec native bindings"
```

---

### Task 3: Final Verification

**Files:**
- No source changes expected unless validation exposes a bug.

**Interfaces:**
- Consumes all previous tasks.
- Produces a clean repository with passing validators.

- [ ] **Step 1: Run all test executables**

Run:

```bash
lake exe json_test
lake exe crypto_hash_test
lake exe codec_test
```

Expected: PASS.

- [ ] **Step 2: Run Lake build**

Run: `lake build`

Expected: PASS. The existing no-default-target warning is acceptable if the command exits 0.

- [ ] **Step 3: Run direct native build**

Run:

```bash
cd native && zig build -Dlean-prefix="$(lean --print-prefix)"
```

Expected: PASS.

- [ ] **Step 4: Check repository status and diff hygiene**

Run:

```bash
git status --porcelain
git diff --check origin/main..HEAD
```

Expected: no unstaged tracked changes and no whitespace errors.

---

## Self-Review Notes

- Spec coverage: public Lean API, C ABI, Zig `std.fmt`/`std.base64`, C shim copy/free ownership, exact tests, regression tests, and final verification are covered.
- Type consistency: `CodecError`, `decodeRawResult`, `hexEncodeLower`, `hexDecode`, `base64Encode`, `base64Decode`, `base64UrlEncode`, and `base64UrlDecode` names are consistent across tasks.
- Scope control: streaming, MIME wrapping, Base32/Base58, Unicode transcoding, and async/I/O-backed codecs remain outside this MVP.
