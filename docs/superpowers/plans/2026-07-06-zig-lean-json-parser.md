# Zig Lean JSON Parser Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the MVP Lean package that validates and tokenizes JSON by calling a Zig native library through a stable C ABI.

**Architecture:** Lean owns the public API and decodes a compact raw result buffer. A Lean-runtime C shim receives Lean `ByteArray` values, calls a Zig C ABI, copies the result into Lean-owned memory, and releases Zig-owned token buffers. Zig uses `std.json.Scanner` for JSON validation and token production.

**Tech Stack:** Lean 4.31.0, Lake 5.0.0, Zig 0.16.0, C ABI, Lean runtime C API, Zig `std.json`.

## Global Constraints

- Do not expose Zig allocator state, Zig slices, Zig structs, or Zig DOM handles to Lean.
- Public Lean API is `validate : ByteArray -> IO Bool` and `parseTokens : ByteArray -> IO (Except JsonError (Array JsonToken))`.
- C ABI only uses integer status codes, byte pointers, byte lengths, fixed-size token structs, and explicit free functions.
- Lean input `ByteArray` remains caller-owned.
- Zig token buffers are freed exactly once by the C shim after copying into a Lean `ByteArray`.
- Tests assert stable error codes and offsets, not full error message text.
- No schema validation, streaming parser, or DOM API in the MVP.

---

## File Structure

- `Lakefile.lean`: Lake package, Lean library target, test executable, and `extern_lib` rule that runs `zig build`.
- `ZigLean.lean`: Top-level module re-exporting `ZigLean.Json`.
- `ZigLean/Json.lean`: Public Lean types and API.
- `ZigLean/Json/Decode.lean`: Pure Lean decoder for the raw native result buffer.
- `ZigLean/Json/FFI.lean`: Opaque extern declarations for the C shim.
- `native/build.zig`: Builds the static library containing Zig code and the C shim.
- `native/include/ziglean_json.h`: Stable C ABI structs and exported Zig function declarations.
- `native/src/json.zig`: Zig JSON validate/tokenize implementation.
- `native/c/lean_json.c`: Lean runtime shim that copies Lean `ByteArray` input and returns raw result buffers.
- `test/JsonTest.lean`: Lean tests for validate, token decode, parse, errors, and repeated calls.

---

### Task 1: Package and Native Build Skeleton

**Files:**
- Create: `Lakefile.lean`
- Create: `ZigLean.lean`
- Create: `ZigLean/Json.lean`
- Create: `ZigLean/Json/FFI.lean`
- Create: `native/build.zig`
- Create: `native/include/ziglean_json.h`
- Create: `native/src/json.zig`
- Create: `native/c/lean_json.c`
- Create: `test/JsonTest.lean`

**Interfaces:**
- Consumes: no project files beyond the approved spec.
- Produces: `ZigLean.Json.validate : ByteArray -> IO Bool`, backed by a native stub.

- [ ] **Step 1: Add Lake package and native build rule**

Create `Lakefile.lean`:

```lean
import Lake
open Lake DSL
open System

package «zig2lean» where
  moreLinkArgs := #["-llean_ziglean"]

lean_lib ZigLean

lean_exe json_test where
  root := `JsonTest
  supportInterpreter := true

extern_lib liblean_ziglean pkg := do
  let libName := nameToStaticLib "lean_ziglean"
  let outDir := pkg.buildDir / "native"
  let libFile := outDir / "lib" / libName
  let zigSrcJob ← inputFile <| pkg.dir / "native" / "src" / "json.zig"
  let cSrcJob ← inputFile <| pkg.dir / "native" / "c" / "lean_json.c"
  let hdrJob ← inputFile <| pkg.dir / "native" / "include" / "ziglean_json.h"
  let depJob := zigSrcJob.mix <| cSrcJob.mix hdrJob
  buildFileAfterDep libFile depJob fun _ => do
    IO.FS.createDirAll libFile.parent.get!
    let leanPrefixOut ← IO.Process.output {
      cmd := "lean",
      args := #["--print-prefix"]
    }
    if leanPrefixOut.exitCode != 0 then
      error s!"lean --print-prefix failed: {leanPrefixOut.stderr}"
    let leanPrefix := leanPrefixOut.stdout.trimRight
    let zigOutPrefix := outDir / "zig-out"
    let procOut ← IO.Process.output {
      cmd := "zig",
      args := #[
        "build",
        "-p", zigOutPrefix.toString,
        s!"-Dlean-prefix={leanPrefix}"
      ],
      cwd := pkg.dir / "native"
    }
    if procOut.exitCode != 0 then
      error s!"zig build failed:\nstdout:\n{procOut.stdout}\nstderr:\n{procOut.stderr}"
    let builtLib := zigOutPrefix / "lib" / libName
    IO.FS.writeBinFile libFile (← IO.FS.readBinFile builtLib)
  return libFile
```

- [ ] **Step 2: Add top-level Lean module**

Create `ZigLean.lean`:

```lean
import ZigLean.Json
```

- [ ] **Step 3: Add public Lean API stub**

Create `ZigLean/Json.lean`:

```lean
import ZigLean.Json.FFI

namespace ZigLean.Json

def validate (input : ByteArray) : IO Bool := do
  pure ((← FFI.validateRaw input) == 0)

end ZigLean.Json
```

- [ ] **Step 4: Add Lean extern declarations**

Create `ZigLean/Json/FFI.lean`:

```lean
namespace ZigLean.Json.FFI

@[extern "lean_ziglean_json_validate_raw"]
opaque validateRaw : @& ByteArray -> IO UInt32

@[extern "lean_ziglean_json_parse_tokens_raw"]
opaque parseTokensRaw : @& ByteArray -> IO ByteArray

end ZigLean.Json.FFI
```

- [ ] **Step 5: Add C ABI header**

Create `native/include/ziglean_json.h`:

```c
#ifndef ZIGLEAN_JSON_H
#define ZIGLEAN_JSON_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
  uint32_t kind;
  uint32_t reserved;
  uint64_t offset;
  uint64_t length;
} ZigLeanJsonToken;

typedef struct {
  uint32_t code;
  uint32_t reserved;
  uint64_t offset;
} ZigLeanJsonError;

uint32_t ziglean_json_validate(const uint8_t* input, uint64_t input_len);

uint32_t ziglean_json_parse_tokens(
  const uint8_t* input,
  uint64_t input_len,
  ZigLeanJsonToken** out_tokens,
  uint64_t* out_len,
  ZigLeanJsonError* out_error
);

void ziglean_json_free_tokens(ZigLeanJsonToken* tokens, uint64_t len);

#ifdef __cplusplus
}
#endif

#endif
```

- [ ] **Step 6: Add Zig static library build**

Create `native/build.zig`:

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const lean_prefix = b.option([]const u8, "lean-prefix", "Lean installation prefix") orelse
        @panic("missing -Dlean-prefix");

    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = "lean_ziglean",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/json.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    lib.addIncludePath(b.path("include"));
    lib.addIncludePath(.{ .cwd_relative = b.fmt("{s}/include", .{lean_prefix}) });
    lib.addCSourceFile(.{
        .file = b.path("c/lean_json.c"),
        .flags = &.{"-std=c11"},
    });
    lib.linkLibC();
    b.installArtifact(lib);
}
```

- [ ] **Step 7: Add Zig native stubs**

Create `native/src/json.zig`:

```zig
const std = @import("std");
const c = @cImport({
    @cInclude("ziglean_json.h");
});

export fn ziglean_json_validate(input: [*]const u8, input_len: u64) u32 {
    _ = input;
    _ = input_len;
    return 0;
}

export fn ziglean_json_parse_tokens(
    input: [*]const u8,
    input_len: u64,
    out_tokens: *?[*]c.ZigLeanJsonToken,
    out_len: *u64,
    out_error: *c.ZigLeanJsonError,
) u32 {
    _ = input;
    _ = input_len;
    out_tokens.* = null;
    out_len.* = 0;
    out_error.* = .{ .code = 0, .reserved = 0, .offset = 0 };
    return 0;
}

export fn ziglean_json_free_tokens(tokens: ?[*]c.ZigLeanJsonToken, len: u64) void {
    _ = len;
    if (tokens) |_| {}
}
```

- [ ] **Step 8: Add Lean runtime C shim stubs**

Create `native/c/lean_json.c`:

```c
#include <lean/lean.h>
#include <stdint.h>
#include <string.h>
#include "ziglean_json.h"

lean_obj_res lean_ziglean_json_validate_raw(b_lean_obj_arg input, lean_obj_arg world) {
  size_t len = lean_sarray_size(input);
  const uint8_t* bytes = lean_sarray_cptr((lean_object*)input);
  uint32_t status = ziglean_json_validate(bytes, (uint64_t)len);
  lean_object* boxed = lean_box_uint32(status);
  return lean_io_result_mk_ok(boxed);
}

lean_obj_res lean_ziglean_json_parse_tokens_raw(b_lean_obj_arg input, lean_obj_arg world) {
  (void)world;
  (void)input;
  lean_object* out = lean_alloc_sarray(1, 16, 16);
  uint8_t* dst = lean_sarray_cptr(out);
  memset(dst, 0, 16);
  return lean_io_result_mk_ok(out);
}
```

- [ ] **Step 9: Add smoke test**

Create `test/JsonTest.lean`:

```lean
import ZigLean

open ZigLean

def bytes (s : String) : ByteArray :=
  s.toUTF8

def assertEq [BEq α] [ToString α] (name : String) (actual expected : α) : IO Unit := do
  if actual != expected then
    throw <| IO.userError s!"{name}: expected {expected}, got {actual}"

def main : IO Unit := do
  assertEq "stub validate" (← Json.validate (bytes "{}")) true
```

- [ ] **Step 10: Run smoke test**

Run: `lake exe json_test`

Expected: PASS with exit code 0 and no output.

- [ ] **Step 11: Commit**

```bash
git add Lakefile.lean ZigLean.lean ZigLean native test
git commit -m "Scaffold Zig backed Lean package"
```

---

### Task 2: Pure Lean Token Types and Raw Decoder

**Files:**
- Modify: `ZigLean/Json.lean`
- Create: `ZigLean/Json/Decode.lean`
- Modify: `test/JsonTest.lean`

**Interfaces:**
- Consumes: `FFI.parseTokensRaw : ByteArray -> IO ByteArray`.
- Produces: `JsonTokenKind`, `JsonToken`, `JsonError`, and `decodeRawResult`.

- [ ] **Step 1: Add failing decoder test**

Replace `test/JsonTest.lean` with:

```lean
import ZigLean
import ZigLean.Json.Decode

open ZigLean
open ZigLean.Json

def bytes (s : String) : ByteArray :=
  s.toUTF8

def assertEq [BEq α] [ToString α] (name : String) (actual expected : α) : IO Unit := do
  if actual != expected then
    throw <| IO.userError s!"{name}: expected {expected}, got {actual}"

def pushU32LE (b : ByteArray) (n : UInt32) : ByteArray :=
  let b := b.push (UInt8.ofNat (n.toNat % 256))
  let b := b.push (UInt8.ofNat ((n.toNat / 256) % 256))
  let b := b.push (UInt8.ofNat ((n.toNat / 65536) % 256))
  b.push (UInt8.ofNat ((n.toNat / 16777216) % 256))

def pushU64LE (b : ByteArray) (n : UInt64) : ByteArray :=
  let rec loop (i : Nat) (acc : ByteArray) : ByteArray :=
    if h : i < 8 then
      loop (i + 1) (acc.push (UInt8.ofNat (((n >>> (8 * i)).toNat) % 256)))
    else
      acc
  loop 0 b

def sampleSuccess : ByteArray :=
  let b := ByteArray.empty
  let b := pushU32LE b 0
  let b := pushU32LE b 2
  let b := pushU64LE b 0
  let b := pushU32LE b 1
  let b := pushU32LE b 0
  let b := pushU64LE b 0
  pushU64LE b 1

def main : IO Unit := do
  assertEq "stub validate" (← Json.validate (bytes "{}")) true
  match decodeRawResult sampleSuccess with
  | Except.ok toks =>
      assertEq "token count" toks.size 1
      assertEq "token kind" toks[0]!.kind JsonTokenKind.objectStart
      assertEq "token offset" toks[0]!.offset 0
      assertEq "token length" toks[0]!.length 1
  | Except.error err =>
      throw <| IO.userError s!"expected success, got error code {err.code}"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `lake exe json_test`

Expected: FAIL because `ZigLean.Json.Decode` and `decodeRawResult` are not defined.

- [ ] **Step 3: Add public types and API**

Replace `ZigLean/Json.lean` with:

```lean
import ZigLean.Json.FFI
import ZigLean.Json.Decode

namespace ZigLean.Json

def validate (input : ByteArray) : IO Bool := do
  pure ((← FFI.validateRaw input) == 0)

def parseTokens (input : ByteArray) : IO (Except JsonError (Array JsonToken)) := do
  pure <| decodeRawResult (← FFI.parseTokensRaw input)

end ZigLean.Json
```

- [ ] **Step 4: Add decoder implementation**

Create `ZigLean/Json/Decode.lean`:

```lean
namespace ZigLean.Json

inductive JsonTokenKind where
  | objectStart
  | objectEnd
  | arrayStart
  | arrayEnd
  | string
  | number
  | bool
  | null
deriving Repr, BEq

instance : ToString JsonTokenKind where
  toString
    | .objectStart => "objectStart"
    | .objectEnd => "objectEnd"
    | .arrayStart => "arrayStart"
    | .arrayEnd => "arrayEnd"
    | .string => "string"
    | .number => "number"
    | .bool => "bool"
    | .null => "null"

structure JsonToken where
  kind : JsonTokenKind
  offset : UInt64
  length : UInt64
deriving Repr, BEq

instance : ToString JsonToken where
  toString t := s!"{t.kind}@{t.offset}+{t.length}"

structure JsonError where
  code : UInt32
  offset : UInt64
  message : String
deriving Repr, BEq

def kindOfCode? : UInt32 -> Option JsonTokenKind
  | 1 => some .objectStart
  | 2 => some .objectEnd
  | 3 => some .arrayStart
  | 4 => some .arrayEnd
  | 5 => some .string
  | 6 => some .number
  | 7 => some .bool
  | 8 => some .null
  | _ => none

def readU32LE? (b : ByteArray) (off : Nat) : Option UInt32 := do
  if off + 4 > b.size then none else
  let b0 := b[off]!.toUInt32
  let b1 := b[off + 1]!.toUInt32
  let b2 := b[off + 2]!.toUInt32
  let b3 := b[off + 3]!.toUInt32
  some (b0 ||| (b1 <<< 8) ||| (b2 <<< 16) ||| (b3 <<< 24))

def readU64LE? (b : ByteArray) (off : Nat) : Option UInt64 := do
  if off + 8 > b.size then none else
  let rec loop (i : Nat) (acc : UInt64) : UInt64 :=
    if h : i < 8 then
      loop (i + 1) (acc ||| (b[off + i]!.toUInt64 <<< (8 * i)))
    else
      acc
  some (loop 0 0)

def decodeRawResult (b : ByteArray) : Except JsonError (Array JsonToken) := Id.run do
  let some status := readU32LE? b 0
    | return Except.error { code := 9001, offset := 0, message := "short native result" }
  let some countOrCode := readU32LE? b 4
    | return Except.error { code := 9001, offset := 0, message := "short native result" }
  let some errOffset := readU64LE? b 8
    | return Except.error { code := 9001, offset := 0, message := "short native result" }
  if status != 0 then
    return Except.error { code := countOrCode, offset := errOffset, message := "json parse failed" }
  let count := countOrCode.toNat
  let expectedSize := 16 + count * 24
  if b.size != expectedSize then
    return Except.error { code := 9002, offset := 0, message := "native result size mismatch" }
  let mut toks := #[]
  for i in [0:count] do
    let base := 16 + i * 24
    let some kindCode := readU32LE? b base
      | return Except.error { code := 9002, offset := 0, message := "missing token kind" }
    let some kind := kindOfCode? kindCode
      | return Except.error { code := 9003, offset := 0, message := "unknown token kind" }
    let some offset := readU64LE? b (base + 8)
      | return Except.error { code := 9002, offset := 0, message := "missing token offset" }
    let some length := readU64LE? b (base + 16)
      | return Except.error { code := 9002, offset := 0, message := "missing token length" }
    toks := toks.push { kind, offset, length }
  return Except.ok toks

end ZigLean.Json
```

- [ ] **Step 5: Run decoder test**

Run: `lake exe json_test`

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add ZigLean/Json.lean ZigLean/Json/Decode.lean test/JsonTest.lean
git commit -m "Add Lean JSON token decoder"
```

---

### Task 3: Zig-backed Validation

**Files:**
- Modify: `native/src/json.zig`
- Modify: `test/JsonTest.lean`

**Interfaces:**
- Consumes: `ziglean_json_validate(const uint8_t*, uint64_t) -> uint32_t`.
- Produces: native validation where `0` means valid JSON and nonzero means invalid JSON.

- [ ] **Step 1: Add failing validation tests**

Append these assertions inside `main` in `test/JsonTest.lean`:

```lean
  assertEq "valid object" (← Json.validate (bytes "{\"a\":1}")) true
  assertEq "valid array" (← Json.validate (bytes "[true,false,null]")) true
  assertEq "invalid trailing comma" (← Json.validate (bytes "{\"a\":1,}")) false
  assertEq "invalid empty input" (← Json.validate (bytes "")) false
```

- [ ] **Step 2: Run test to verify it fails**

Run: `lake exe json_test`

Expected: FAIL because the native stub returns success for invalid JSON.

- [ ] **Step 3: Implement validation in Zig**

Replace the `ziglean_json_validate` function in `native/src/json.zig` with:

```zig
export fn ziglean_json_validate(input: [*]const u8, input_len: u64) u32 {
    const bytes = input[0..@intCast(input_len)];
    var scanner = std.json.Scanner.initCompleteInput(std.heap.c_allocator, bytes);
    defer scanner.deinit();

    while (true) {
        const token = scanner.next() catch return 1;
        switch (token) {
            .end_of_document => return 0,
            else => {},
        }
    }
}
```

- [ ] **Step 4: Run validation tests**

Run: `lake exe json_test`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add native/src/json.zig test/JsonTest.lean
git commit -m "Validate JSON with Zig std json"
```

---

### Task 4: Native Tokenization Success Path

**Files:**
- Modify: `native/src/json.zig`
- Modify: `native/c/lean_json.c`
- Modify: `test/JsonTest.lean`

**Interfaces:**
- Consumes: Zig `ziglean_json_parse_tokens`.
- Produces: `Json.parseTokens` success for objects, arrays, strings, numbers, booleans, and null.

- [ ] **Step 1: Add failing parse tests**

Append these assertions inside `main` in `test/JsonTest.lean`:

```lean
  match ← Json.parseTokens (bytes "{\"a\":1,\"b\":[true,null]}") with
  | Except.error err =>
      throw <| IO.userError s!"parse success expected, got {err.code}"
  | Except.ok toks =>
      assertEq "parse token count" toks.size 10
      assertEq "first token" toks[0]!.kind JsonTokenKind.objectStart
      assertEq "key token" toks[1]!.kind JsonTokenKind.string
      assertEq "number token" toks[2]!.kind JsonTokenKind.number
      assertEq "array token" toks[5]!.kind JsonTokenKind.arrayStart
      assertEq "bool token" toks[6]!.kind JsonTokenKind.bool
      assertEq "null token" toks[7]!.kind JsonTokenKind.null
      assertEq "last token" toks[9]!.kind JsonTokenKind.objectEnd
```

- [ ] **Step 2: Run test to verify it fails**

Run: `lake exe json_test`

Expected: FAIL because the native parse stub returns zero tokens.

- [ ] **Step 3: Add token append helpers in Zig**

Insert above `ziglean_json_parse_tokens` in `native/src/json.zig`:

```zig
const TokenList = std.ArrayList(c.ZigLeanJsonToken);

fn appendToken(list: *TokenList, kind: u32, offset: usize, length: usize) !void {
    try list.append(.{
        .kind = kind,
        .reserved = 0,
        .offset = @intCast(offset),
        .length = @intCast(length),
    });
}

fn spanFromSlice(input: []const u8, slice: []const u8) struct { offset: usize, length: usize } {
    const start = @intFromPtr(slice.ptr) - @intFromPtr(input.ptr);
    return .{ .offset = start, .length = slice.len };
}
```

- [ ] **Step 4: Implement tokenization in Zig**

Replace `ziglean_json_parse_tokens` and `ziglean_json_free_tokens` in `native/src/json.zig` with:

```zig
export fn ziglean_json_parse_tokens(
    input: [*]const u8,
    input_len: u64,
    out_tokens: *?[*]c.ZigLeanJsonToken,
    out_len: *u64,
    out_error: *c.ZigLeanJsonError,
) u32 {
    const bytes = input[0..@intCast(input_len)];
    var scanner = std.json.Scanner.initCompleteInput(std.heap.c_allocator, bytes);
    defer scanner.deinit();

    var list = TokenList.init(std.heap.c_allocator);
    errdefer list.deinit();

    while (true) {
        const before = scanner.cursor;
        const token = scanner.next() catch {
            out_tokens.* = null;
            out_len.* = 0;
            out_error.* = .{ .code = 1, .reserved = 0, .offset = @intCast(scanner.cursor) };
            return 1;
        };
        const after = scanner.cursor;
        switch (token) {
            .object_begin => appendToken(&list, 1, after - 1, 1) catch return 2,
            .object_end => appendToken(&list, 2, after - 1, 1) catch return 2,
            .array_begin => appendToken(&list, 3, after - 1, 1) catch return 2,
            .array_end => appendToken(&list, 4, after - 1, 1) catch return 2,
            .string => |s| {
                const span = spanFromSlice(bytes, s);
                appendToken(&list, 5, span.offset, span.length) catch return 2;
            },
            .number => |s| {
                const span = spanFromSlice(bytes, s);
                appendToken(&list, 6, span.offset, span.length) catch return 2;
            },
            .true => appendToken(&list, 7, after - 4, 4) catch return 2,
            .false => appendToken(&list, 7, after - 5, 5) catch return 2,
            .null => appendToken(&list, 8, after - 4, 4) catch return 2,
            .end_of_document => {
                out_len.* = @intCast(list.items.len);
                const owned = list.toOwnedSlice() catch return 2;
                out_tokens.* = owned.ptr;
                out_error.* = .{ .code = 0, .reserved = 0, .offset = 0 };
                return 0;
            },
            else => {
                out_tokens.* = null;
                out_len.* = 0;
                out_error.* = .{ .code = 3, .reserved = 0, .offset = @intCast(before) };
                return 3;
            },
        }
    }
}

export fn ziglean_json_free_tokens(tokens: ?[*]c.ZigLeanJsonToken, len: u64) void {
    if (tokens) |ptr| {
        const slice = ptr[0..@intCast(len)];
        std.heap.c_allocator.free(slice);
    }
}
```

- [ ] **Step 5: Implement C shim result buffer**

Replace `lean_ziglean_json_parse_tokens_raw` in `native/c/lean_json.c` with:

```c
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

lean_obj_res lean_ziglean_json_parse_tokens_raw(b_lean_obj_arg input, lean_obj_arg world) {
  (void)world;
  size_t input_len = lean_sarray_size(input);
  const uint8_t* input_bytes = lean_sarray_cptr((lean_object*)input);

  ZigLeanJsonToken* tokens = 0;
  uint64_t token_len = 0;
  ZigLeanJsonError err = {0, 0, 0};
  uint32_t status = ziglean_json_parse_tokens(
    input_bytes,
    (uint64_t)input_len,
    &tokens,
    &token_len,
    &err
  );

  size_t out_len = 16u + (status == 0 ? ((size_t)token_len * 24u) : 0u);
  lean_object* out = lean_alloc_sarray(1, out_len, out_len);
  uint8_t* dst = lean_sarray_cptr(out);
  write_u32(dst, status);
  write_u32(dst + 4, status == 0 ? (uint32_t)token_len : err.code);
  write_u64(dst + 8, err.offset);

  if (status == 0) {
    for (uint64_t i = 0; i < token_len; i++) {
      uint8_t* base = dst + 16u + ((size_t)i * 24u);
      write_u32(base, tokens[i].kind);
      write_u32(base + 4, tokens[i].reserved);
      write_u64(base + 8, tokens[i].offset);
      write_u64(base + 16, tokens[i].length);
    }
  }

  ziglean_json_free_tokens(tokens, token_len);
  return lean_io_result_mk_ok(out);
}
```

- [ ] **Step 6: Run parse tests**

Run: `lake exe json_test`

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add native/src/json.zig native/c/lean_json.c test/JsonTest.lean
git commit -m "Tokenize JSON through Zig native parser"
```

---

### Task 5: Error Mapping and Ownership Stress Tests

**Files:**
- Modify: `test/JsonTest.lean`

**Interfaces:**
- Consumes: `Json.parseTokens : ByteArray -> IO (Except JsonError (Array JsonToken))`.
- Produces: test coverage for invalid JSON and repeated parse/free cycles.

- [ ] **Step 1: Add error and repeated-call tests**

Append these assertions inside `main` in `test/JsonTest.lean`:

```lean
  match ← Json.parseTokens (bytes "{\"a\":1,}") with
  | Except.ok toks =>
      throw <| IO.userError s!"parse error expected, got {toks.size} tokens"
  | Except.error err =>
      assertEq "error code" (err.code == 1) true
      assertEq "error offset present" (err.offset > 0) true

  for _ in [0:100] do
    match ← Json.parseTokens (bytes "[1,2,3]") with
    | Except.error err =>
        throw <| IO.userError s!"repeat parse failed with {err.code}"
    | Except.ok toks =>
        assertEq "repeat token count" toks.size 5
```

- [ ] **Step 2: Run tests**

Run: `lake exe json_test`

Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add test/JsonTest.lean
git commit -m "Cover JSON parser errors and ownership"
```

---

### Task 6: Final Verification

**Files:**
- No source changes expected.

**Interfaces:**
- Consumes: all previous tasks.
- Produces: a clean repository with passing validators.

- [ ] **Step 1: Run Lean test executable**

Run: `lake exe json_test`

Expected: PASS.

- [ ] **Step 2: Run Lake build**

Run: `lake build`

Expected: PASS.

- [ ] **Step 3: Run Zig build directly**

Run: `cd native && zig build -Dlean-prefix="$(lean --print-prefix)"`

Expected: PASS.

- [ ] **Step 4: Check repository status**

Run: `git status --porcelain`

Expected: no output.

---

## Self-Review Notes

- Spec coverage: validation, tokenization, narrow C ABI, Lean-owned public API, error codes, offsets, and repeated parse/free testing are covered.
- Type consistency: `JsonTokenKind`, `JsonToken`, `JsonError`, `validate`, `parseTokens`, `decodeRawResult`, and FFI names are consistent across tasks.
- Scope control: DOM handles, schema validation, streaming, and path query remain outside the MVP.
