# Zig-backed Lean Random / UUID Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `ZigLean.Random` and `ZigLean.Uuid` modules backed by Zig `std.crypto.random`, exposing `randomBytes` and `uuid4` to Lean.

**Architecture:** Follow the existing Zig↔C↔Lean binding pattern. Zig allocates output buffers with `std.heap.c_allocator`; C shims copy outputs into Lean `ByteArray` / `String` and free the Zig buffers. Lean owns the public API.

**Tech Stack:** Zig 0.16, Lean 4, Lake, C11.

## Global Constraints

- Zig output buffers must be allocated with `std.heap.c_allocator`.
- C shims must free Zig output buffers exactly once after copying.
- Lean extern names must match the C shim function names exactly.
- All new native files must be registered in `native/src/root.zig`, `native/build.zig`, and `lakefile.lean`.
- Tests must be added as separate `lean_exe` entries in `lakefile.lean` and listed in the `test` script.

---

### Task 1: Add Zig random implementation

**Files:**
- Create: `native/src/random.zig`

**Interfaces:**
- Produces: `ziglean_random_bytes(len, out_result) -> u32` with result struct `ZigLeanRandomResult`.

- [ ] **Step 1: Write `native/src/random.zig`**

```zig
const std = @import("std");
const builtin = @import("builtin");
const c = @cImport({
    @cInclude("ziglean_random.h");
});

const STATUS_OK: u32 = 0;
const STATUS_TOO_LARGE: u32 = 1;
const STATUS_ALLOC: u32 = 2;
const STATUS_RANDOM: u32 = 3;

fn setError(out: *c.ZigLeanRandomResult, status: u32) u32 {
    out.* = .{ .status = status, .reserved = 0, .out_len = 0, .out = null };
    return status;
}

fn setSuccess(out: *c.ZigLeanRandomResult, buf: []u8) u32 {
    out.* = .{ .status = STATUS_OK, .reserved = 0, .out_len = @intCast(buf.len), .out = buf.ptr };
    return STATUS_OK;
}

pub fn fillRandom(buf: []u8) u32 {
    if (buf.len == 0) return STATUS_OK;
    switch (builtin.os.tag) {
        .linux => {
            var pos: usize = 0;
            while (pos < buf.len) {
                const n = std.c.getrandom(buf.ptr + pos, buf.len - pos, 0);
                if (n < 0) {
                    const errno = std.c.getErrno();
                    if (errno == .INTR) continue;
                    return STATUS_RANDOM;
                }
                if (n == 0) return STATUS_RANDOM;
                pos += @intCast(n);
            }
            return STATUS_OK;
        },
        .macos, .ios, .tvos, .watchos, .visionos, .freebsd, .netbsd, .openbsd, .dragonfly => {
            std.c.arc4random_buf(buf.ptr, buf.len);
            return STATUS_OK;
        },
        else => @compileError("unsupported OS for secure random bytes"),
    }
}

export fn ziglean_random_bytes(len: u64, out_result: *c.ZigLeanRandomResult) u32 {
    if (len > std.math.maxInt(usize)) return setError(out_result, STATUS_TOO_LARGE);
    const size: usize = @intCast(len);
    const out = std.heap.c_allocator.alloc(u8, size) catch return setError(out_result, STATUS_ALLOC);
    const status = fillRandom(out);
    if (status != STATUS_OK) {
        std.heap.c_allocator.free(out);
        return setError(out_result, status);
    }
    return setSuccess(out_result, out);
}

export fn ziglean_random_free(ptr: ?[*]u8, len: u64) void {
    if (len > std.math.maxInt(usize)) return;
    if (ptr) |p| {
        std.heap.c_allocator.free(p[0..@intCast(len)]);
    }
}
```

- [ ] **Step 2: Verify Zig file compiles standalone**

Run: `cd native && zig fmt src/random.zig`
Expected: no output (success).

- [ ] **Step 3: Commit**

```bash
git add native/src/random.zig
git commit -m "feat(random): add Zig CSPRNG random bytes implementation"
```

---

### Task 2: Add C header and shim for random

**Files:**
- Create: `native/include/ziglean_random.h`
- Create: `native/c/lean_random.c`

**Interfaces:**
- Produces: `lean_ziglean_random_bytes` for Lean extern.

- [ ] **Step 1: Write `native/include/ziglean_random.h`**

```c
#ifndef ZIGLEAN_RANDOM_H
#define ZIGLEAN_RANDOM_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
  uint32_t status;
  uint32_t reserved;
  uint64_t out_len;
  uint8_t* out;
} ZigLeanRandomResult;

uint32_t ziglean_random_bytes(uint64_t len, ZigLeanRandomResult* out_result);
void ziglean_random_free(uint8_t* ptr, uint64_t len);

#ifdef __cplusplus
}
#endif

#endif
```

- [ ] **Step 2: Write `native/c/lean_random.c`**

```c
#include <lean/lean.h>
#include <stdint.h>
#include <string.h>
#include "ziglean_random.h"

static lean_obj_res mk_random_error(const char* message) {
  lean_object* str = lean_mk_string(message);
  lean_object* err = lean_mk_io_user_error(str);
  return lean_io_result_mk_error(err);
}

lean_obj_res lean_ziglean_random_bytes(uint64_t len, lean_obj_arg world) {
  (void)world;
  ZigLeanRandomResult result = {0, 0, 0, 0};
  uint32_t status = ziglean_random_bytes(len, &result);
  if (status != 0) {
    // Zig guarantees result.out is null on error; nothing to free.
    return mk_random_error("random bytes generation failed");
  }
  lean_object* out = lean_alloc_sarray(1, (size_t)result.out_len, (size_t)result.out_len);
  if (result.out_len > 0) {
    memcpy(lean_sarray_cptr(out), result.out, (size_t)result.out_len);
  }
  ziglean_random_free(result.out, result.out_len);
  return lean_io_result_mk_ok(out);
}
```

- [ ] **Step 3: Commit**

```bash
git add native/include/ziglean_random.h native/c/lean_random.c
git commit -m "feat(random): add C header and Lean shim"
```

---

### Task 3: Add Lean Random FFI and public API

**Files:**
- Create: `ZigLean/Random.lean`
- Create: `ZigLean/Random/FFI.lean`

**Interfaces:**
- Consumes: `lean_ziglean_random_bytes` from C.
- Produces: `ZigLean.Random.randomBytes : Nat -> IO ByteArray`.

- [ ] **Step 1: Write `ZigLean/Random/FFI.lean`**

```lean
namespace ZigLean.Random.FFI

@[extern "lean_ziglean_random_bytes"]
opaque randomBytesRaw : UInt64 -> IO ByteArray

end ZigLean.Random.FFI
```

- [ ] **Step 2: Write `ZigLean/Random.lean`**

```lean
import ZigLean.Random.FFI

namespace ZigLean.Random

def randomBytes (n : Nat) : IO ByteArray :=
  FFI.randomBytesRaw (UInt64.ofNat n)

end ZigLean.Random
```

- [ ] **Step 3: Commit**

```bash
git add ZigLean/Random.lean ZigLean/Random/FFI.lean
git commit -m "feat(random): add Lean Random API"
```

---

### Task 4: Add Zig UUID v4 implementation

**Files:**
- Create: `native/src/uuid.zig`

**Interfaces:**
- Produces: `ziglean_uuid_v4(out_result) -> u32` with result struct `ZigLeanUuidResult`.

- [ ] **Step 1: Write `native/src/uuid.zig`**

```zig
const std = @import("std");
const random = @import("random.zig");
const c = @cImport({
    @cInclude("ziglean_uuid.h");
});

const STATUS_OK: u32 = 0;
const STATUS_ALLOC: u32 = 1;
const STATUS_RANDOM: u32 = 2;

const UUID_LEN: usize = 36;

fn setError(out: *c.ZigLeanUuidResult, status: u32) u32 {
    out.* = .{ .status = status, .reserved = 0, .out_len = 0, .out = null };
    return status;
}

fn setSuccess(out: *c.ZigLeanUuidResult, buf: []u8) u32 {
    out.* = .{ .status = STATUS_OK, .reserved = 0, .out_len = @intCast(buf.len), .out = buf.ptr };
    return STATUS_OK;
}

fn hexChar(nibble: u4) u8 {
    return "0123456789abcdef"[nibble];
}

export fn ziglean_uuid_v4(out_result: *c.ZigLeanUuidResult) u32 {
    var bytes: [16]u8 = undefined;
    const status = random.fillRandom(&bytes);
    if (status != STATUS_OK) return setError(out_result, status);

    bytes[6] = (bytes[6] & 0x0F) | 0x40;
    bytes[8] = (bytes[8] & 0x3F) | 0x80;

    const out = std.heap.c_allocator.alloc(u8, UUID_LEN) catch return setError(out_result, STATUS_ALLOC);

    var out_idx: usize = 0;
    for (bytes, 0..) |b, i| {
        if (i == 4 or i == 6 or i == 8 or i == 10) {
            out[out_idx] = '-';
            out_idx += 1;
        }
        out[out_idx] = hexChar(@truncate(b >> 4));
        out[out_idx + 1] = hexChar(@truncate(b & 0x0F));
        out_idx += 2;
    }

    return setSuccess(out_result, out);
}

export fn ziglean_uuid_free(ptr: ?[*]u8, len: u64) void {
    if (len > std.math.maxInt(usize)) return;
    if (ptr) |p| {
        std.heap.c_allocator.free(p[0..@intCast(len)]);
    }
}
```

- [ ] **Step 2: Verify Zig file compiles standalone**

Run: `cd native && zig fmt src/uuid.zig`
Expected: no output (success).

- [ ] **Step 3: Commit**

```bash
git add native/src/uuid.zig
git commit -m "feat(uuid): add Zig UUID v4 implementation"
```

---

### Task 5: Add C header and shim for UUID

**Files:**
- Create: `native/include/ziglean_uuid.h`
- Create: `native/c/lean_uuid.c`

**Interfaces:**
- Produces: `lean_ziglean_uuid_v4` for Lean extern.

- [ ] **Step 1: Write `native/include/ziglean_uuid.h`**

```c
#ifndef ZIGLEAN_UUID_H
#define ZIGLEAN_UUID_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
  uint32_t status;
  uint32_t reserved;
  uint64_t out_len;
  uint8_t* out;
} ZigLeanUuidResult;

uint32_t ziglean_uuid_v4(ZigLeanUuidResult* out_result);
void ziglean_uuid_free(uint8_t* ptr, uint64_t len);

#ifdef __cplusplus
}
#endif

#endif
```

- [ ] **Step 2: Write `native/c/lean_uuid.c`**

```c
#include <lean/lean.h>
#include <stdint.h>
#include <string.h>
#include "ziglean_uuid.h"

static lean_obj_res mk_uuid_error(const char* message) {
  lean_object* str = lean_mk_string(message);
  lean_object* err = lean_mk_io_user_error(str);
  return lean_io_result_mk_error(err);
}

lean_obj_res lean_ziglean_uuid_v4(lean_obj_arg world) {
  (void)world;
  ZigLeanUuidResult result = {0, 0, 0, 0};
  uint32_t status = ziglean_uuid_v4(&result);
  if (status != 0) {
    // Zig guarantees result.out is null on error; nothing to free.
    return mk_uuid_error("uuid v4 generation failed");
  }
  lean_object* out = lean_mk_string_from_bytes((const char*)result.out, (size_t)result.out_len);
  ziglean_uuid_free(result.out, result.out_len);
  return lean_io_result_mk_ok(out);
}
```

- [ ] **Step 3: Commit**

```bash
git add native/include/ziglean_uuid.h native/c/lean_uuid.c
git commit -m "feat(uuid): add C header and Lean shim"
```

---

### Task 6: Add Lean Uuid FFI and public API

**Files:**
- Create: `ZigLean/Uuid.lean`
- Create: `ZigLean/Uuid/FFI.lean`

**Interfaces:**
- Consumes: `lean_ziglean_uuid_v4` from C.
- Produces: `ZigLean.Uuid.uuid4 : IO String`.

- [ ] **Step 1: Write `ZigLean/Uuid/FFI.lean`**

```lean
namespace ZigLean.Uuid.FFI

@[extern "lean_ziglean_uuid_v4"]
opaque uuid4Raw : IO String

end ZigLean.Uuid.FFI
```

- [ ] **Step 2: Write `ZigLean/Uuid.lean`**

```lean
import ZigLean.Uuid.FFI

namespace ZigLean.Uuid

def uuid4 : IO String :=
  FFI.uuid4Raw

end ZigLean.Uuid
```

- [ ] **Step 3: Commit**

```bash
git add ZigLean/Uuid.lean ZigLean/Uuid/FFI.lean
git commit -m "feat(uuid): add Lean Uuid API"
```

---

### Task 7: Register new Zig modules in native build

**Files:**
- Modify: `native/src/root.zig`
- Modify: `native/build.zig`

**Interfaces:**
- Consumes: `random.zig`, `uuid.zig`.

- [ ] **Step 1: Update `native/src/root.zig`**

Add at the end of the `comptime` block:

```zig
_ = @import("random.zig");
_ = @import("uuid.zig");
```

Full file should be:

```zig
comptime {
    _ = @import("json.zig");
    _ = @import("json_stream.zig");
    _ = @import("crypto_hash.zig");
    _ = @import("crypto_hash_stream.zig");
    _ = @import("crypto_kdf.zig");
    _ = @import("crypto_sign.zig");
    _ = @import("crypto_aead.zig");
    _ = @import("hash_checksum.zig");
    _ = @import("leb128.zig");
    _ = @import("codec.zig");
    _ = @import("compress.zig");
    _ = @import("random.zig");
    _ = @import("uuid.zig");
}
```

- [ ] **Step 2: Update `native/build.zig`**

Add after the `lean_leb128.c` block:

```zig
lib.root_module.addCSourceFile(.{
    .file = b.path("c/lean_random.c"),
    .flags = &.{ "-std=c11", "-fno-sanitize=undefined" },
});
lib.root_module.addCSourceFile(.{
    .file = b.path("c/lean_uuid.c"),
    .flags = &.{ "-std=c11", "-fno-sanitize=undefined" },
});
```

- [ ] **Step 3: Commit**

```bash
git add native/src/root.zig native/build.zig
git commit -m "build: register random and uuid modules"
```

---

### Task 8: Register new native files in Lake build

**Files:**
- Modify: `lakefile.lean`

**Interfaces:**
- Consumes: new `.zig`, `.c`, `.h` files.

- [ ] **Step 1: Add input file jobs**

After `compressCSrcJob` and `compressHdrJob`, add:

```lean
let randomSrcJob ← inputFile (pkg.dir / "native" / "src" / "random.zig") true
let uuidSrcJob ← inputFile (pkg.dir / "native" / "src" / "uuid.zig") true
let randomCSrcJob ← inputFile (pkg.dir / "native" / "c" / "lean_random.c") true
let uuidCSrcJob ← inputFile (pkg.dir / "native" / "c" / "lean_uuid.c") true
let randomHdrJob ← inputFile (pkg.dir / "native" / "include" / "ziglean_random.h") true
let uuidHdrJob ← inputFile (pkg.dir / "native" / "include" / "ziglean_uuid.h") true
```

- [ ] **Step 2: Extend the dependency mix chain**

Extend the final `compressCSrcJob.mix <| compressHdrJob` chain to end with:

```lean
compressCSrcJob.mix <| compressHdrJob.mix <|
  randomSrcJob.mix <| uuidSrcJob.mix <|
  randomCSrcJob.mix <| uuidCSrcJob.mix <|
  randomHdrJob.mix uuidHdrJob
```

- [ ] **Step 3: Commit**

```bash
git add lakefile.lean
git commit -m "build(lake): track random and uuid native files"
```

---

### Task 9: Re-export Random and Uuid from ZigLean

**Files:**
- Modify: `ZigLean.lean`

**Interfaces:**
- Produces: `ZigLean.Random`, `ZigLean.Uuid` available from `import ZigLean`.

- [ ] **Step 1: Update `ZigLean.lean`**

```lean
import ZigLean.Json
import ZigLean.Crypto
import ZigLean.Codec
import ZigLean.Compress
import ZigLean.Hash
import ZigLean.Leb128
import ZigLean.Random
import ZigLean.Uuid
```

- [ ] **Step 2: Commit**

```bash
git add ZigLean.lean
git commit -m "feat: re-export Random and Uuid from ZigLean"
```

---

### Task 10: Add Random tests

**Files:**
- Create: `test/RandomTest.lean`
- Modify: `lakefile.lean`

**Interfaces:**
- Consumes: `ZigLean.Random.randomBytes`.

- [ ] **Step 1: Write `test/RandomTest.lean`**

```lean
import ZigLean

namespace RandomTest

open ZigLean.Random

def assertEq [BEq α] [ToString α] (name : String) (actual expected : α) : IO Unit := do
  if actual != expected then
    throw <| IO.userError s!"{name}: expected {expected}, got {actual}"

def main : IO Unit := do
  let empty ← randomBytes 0
  assertEq "random bytes 0 length" empty.size 0

  let sixteen ← randomBytes 16
  assertEq "random bytes 16 length" sixteen.size 16

  let thirtyTwo ← randomBytes 32
  assertEq "random bytes 32 length" thirtyTwo.size 32

  let a ← randomBytes 32
  let b ← randomBytes 32
  if a == b then
    throw <| IO.userError "random bytes should differ between calls"

end RandomTest

def main : IO Unit :=
  RandomTest.main
```

- [ ] **Step 2: Add test executable to `lakefile.lean`**

Add after the `json_pointer_test` block:

```lean
lean_exe random_test where
  root := `RandomTest
  srcDir := "test"
  supportInterpreter := true
```

Add `("RandomTest", "random_test")` to the `suites` array in the `test` script.

- [ ] **Step 3: Commit**

```bash
git add test/RandomTest.lean lakefile.lean
git commit -m "test(random): add RandomTest suite"
```

---

### Task 11: Add UUID tests

**Files:**
- Create: `test/UuidTest.lean`
- Modify: `lakefile.lean`

**Interfaces:**
- Consumes: `ZigLean.Uuid.uuid4`.

- [ ] **Step 1: Write `test/UuidTest.lean`**

```lean
import ZigLean

namespace UuidTest

open ZigLean.Uuid

def assertEq [BEq α] [ToString α] (name : String) (actual expected : α) : IO Unit := do
  if actual != expected then
    throw <| IO.userError s!"{name}: expected {expected}, got {actual}"

def isValidUuid4 (s : String) : Bool :=
  s.length == 36 &&
  s[8] == '-' && s[13] == '-' && s[18] == '-' && s[23] == '-' &&
  s[14] == '4' &&
  (s[19] == '8' || s[19] == '9' || s[19] == 'a' || s[19] == 'b')

def main : IO Unit := do
  let u1 ← uuid4
  assertEq "uuid4 length" u1.length 36
  unless isValidUuid4 u1 do
    throw <| IO.userError s!"uuid4 format invalid: {u1}"

  let u2 ← uuid4
  if u1 == u2 then
    throw <| IO.userError "uuid4 values should differ between calls"

end UuidTest

def main : IO Unit :=
  UuidTest.main
```

- [ ] **Step 2: Add test executable to `lakefile.lean`**

Add after the `random_test` block:

```lean
lean_exe uuid_test where
  root := `UuidTest
  srcDir := "test"
  supportInterpreter := true
```

Add `("UuidTest", "uuid_test")` to the `suites` array in the `test` script.

- [ ] **Step 3: Commit**

```bash
git add test/UuidTest.lean lakefile.lean
git commit -m "test(uuid): add UuidTest suite"
```

---

### Task 12: Run full test suite

**Files:**
- None (verification only).

**Interfaces:**
- Consumes: all previous tasks.

- [ ] **Step 1: Build and run tests**

Run: `lake test`
Expected: all suites pass, ending with `All tests passed.`

- [ ] **Step 2: If failures occur, fix and re-run**

Fix any compile or runtime errors, then re-run `lake test`.

- [ ] **Step 3: Final commit**

```bash
git commit -am "test: verify random and uuid modules pass lake test"
```

---

## Self-Review

**Spec coverage:**
- `randomBytes` one-shot API → Task 1-3
- `uuid4` one-shot API → Task 4-6
- OS-backed secure random via `fillRandom` (`std.c.getrandom` / `std.c.arc4random_buf`) → Task 1, 4
- RFC 4122 version/variant bits → Task 4
- Build integration → Task 7-9
- Tests → Task 10-12

**Placeholder scan:**
- No `TBD`, `TODO`, or vague steps.
- Every code block contains complete content.

**Type consistency:**
- `lean_ziglean_random_bytes` extern name matches in `FFI.lean`, C shim, and Zig export.
- `lean_ziglean_uuid_v4` extern name matches across all layers.
- `ZigLeanRandomResult` and `ZigLeanUuidResult` field names consistent between C headers and Zig `@cImport` usage.
