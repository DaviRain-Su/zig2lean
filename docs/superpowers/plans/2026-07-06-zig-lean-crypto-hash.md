# Zig Lean Crypto Hash Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `ZigLean.Crypto.Hash` with Zig-backed SHA-256, BLAKE3, and HMAC-SHA256 one-shot helpers.

**Architecture:** Lean exposes simple `ByteArray -> IO ByteArray` APIs. A Lean runtime C shim allocates 32-byte Lean `ByteArray` outputs and calls fixed-buffer Zig C ABI functions. Zig uses `std.crypto.hash.sha2.Sha256`, `std.crypto.hash.Blake3`, and `std.crypto.auth.hmac.sha2.HmacSha256`.

**Tech Stack:** Lean 4.31.0, Lake 5.0.0, Zig 0.16.0, C ABI, Lean runtime C API, Zig `std.crypto`.

## Global Constraints

- The MVP exposes `sha256 : ByteArray -> IO ByteArray`, `blake3 : ByteArray -> IO ByteArray`, and `hmacSha256 : ByteArray -> ByteArray -> IO ByteArray`.
- All three outputs are exactly 32 bytes.
- No streaming hash context in the MVP.
- No keyed BLAKE3 in the MVP.
- No random number API in the MVP.
- No signature, KDF, password hashing, or AEAD API in the MVP.
- No exposure of Zig hash state, allocator state, or internal structs to Lean.
- The Zig-facing C ABI uses caller-provided fixed output buffers instead of Zig allocation.
- Return code `0` means success. Nonzero codes are reserved for future error states.
- If Zig returns a nonzero status, the C shim returns an `IO.userError`.
- Extend the existing `liblean_ziglean` native static library instead of creating a second library.
- Tests assert exact byte output through hex encoding helper functions in Lean.

---

## File Structure

- `ZigLean.lean`: re-export `ZigLean.Crypto`.
- `ZigLean/Crypto.lean`: re-export `ZigLean.Crypto.Hash`.
- `ZigLean/Crypto/Hash.lean`: public `sha256`, `blake3`, `hmacSha256` APIs.
- `ZigLean/Crypto/Hash/FFI.lean`: extern declarations for Lean runtime C shim functions.
- `native/include/ziglean_crypto_hash.h`: C ABI constants and Zig-exported function declarations.
- `native/src/root.zig`: native static library root importing JSON and crypto hash Zig modules.
- `native/src/crypto_hash.zig`: Zig `std.crypto` one-shot implementation.
- `native/c/lean_crypto_hash.c`: Lean runtime C shim for crypto hash functions.
- `native/build.zig`: include the new C shim and switch root source to `src/root.zig`.
- `lakefile.lean`: add new native files as dependencies of the existing `extern_lib`.
- `test/CryptoHashTest.lean`: crypto test executable.
- `test/JsonTest.lean`: unchanged.

---

### Task 1: Lean API and Failing Crypto Tests

**Files:**
- Modify: `ZigLean.lean`
- Create: `ZigLean/Crypto.lean`
- Create: `ZigLean/Crypto/Hash.lean`
- Create: `ZigLean/Crypto/Hash/FFI.lean`
- Modify: `lakefile.lean`
- Create: `test/CryptoHashTest.lean`

**Interfaces:**
- Consumes: no native implementation yet.
- Produces:
  - `ZigLean.Crypto.Hash.sha256 : ByteArray -> IO ByteArray`
  - `ZigLean.Crypto.Hash.blake3 : ByteArray -> IO ByteArray`
  - `ZigLean.Crypto.Hash.hmacSha256 : ByteArray -> ByteArray -> IO ByteArray`
  - Lake executable `crypto_hash_test`.

- [ ] **Step 1: Write the failing crypto tests**

Create `test/CryptoHashTest.lean`:

```lean
import ZigLean

open ZigLean.Crypto.Hash

def bytes (s : String) : ByteArray :=
  s.toUTF8

def assertEq [BEq α] [ToString α] (name : String) (actual expected : α) : IO Unit := do
  if actual != expected then
    throw <| IO.userError s!"{name}: expected {expected}, got {actual}"

def assertByteArrayEq (name : String) (actual expected : ByteArray) : IO Unit := do
  if actual != expected then
    throw <| IO.userError s!"{name}: expected {expected.size} bytes, got {actual.size} bytes"

def hexVal? : Char -> Option UInt8
  | '0' => some 0
  | '1' => some 1
  | '2' => some 2
  | '3' => some 3
  | '4' => some 4
  | '5' => some 5
  | '6' => some 6
  | '7' => some 7
  | '8' => some 8
  | '9' => some 9
  | 'a' => some 10
  | 'b' => some 11
  | 'c' => some 12
  | 'd' => some 13
  | 'e' => some 14
  | 'f' => some 15
  | 'A' => some 10
  | 'B' => some 11
  | 'C' => some 12
  | 'D' => some 13
  | 'E' => some 14
  | 'F' => some 15
  | _ => none

def hexToBytes? (s : String) : Option ByteArray :=
  let rec loop : List Char -> ByteArray -> Option ByteArray
    | [], acc => some acc
    | hi :: lo :: rest, acc => do
        let h ← hexVal? hi
        let l ← hexVal? lo
        loop rest (acc.push (UInt8.ofNat (h.toNat * 16 + l.toNat)))
    | _ :: [], _ => none
  loop s.toList ByteArray.empty

def expectHex (name : String) (actual : ByteArray) (expectedHex : String) : IO Unit := do
  match hexToBytes? expectedHex with
  | none => throw <| IO.userError s!"{name}: invalid expected hex literal"
  | some expected => assertByteArrayEq name actual expected

def hmacKey : ByteArray :=
  let rec loop (i : Nat) (acc : ByteArray) : ByteArray :=
    if _h : i < 20 then
      loop (i + 1) (acc.push 0x0b)
    else
      acc
  loop 0 ByteArray.empty

def main : IO Unit := do
  let shaEmpty ← sha256 ByteArray.empty
  assertEq "sha256 empty length" shaEmpty.size 32
  expectHex "sha256 empty" shaEmpty
    "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"

  let shaAbc ← sha256 (bytes "abc")
  assertEq "sha256 abc length" shaAbc.size 32
  expectHex "sha256 abc" shaAbc
    "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"

  let blakeEmpty ← blake3 ByteArray.empty
  assertEq "blake3 empty length" blakeEmpty.size 32
  expectHex "blake3 empty" blakeEmpty
    "af1349b9f5f9a1a6a0404dea36dcc9499bcb25c9adc112b7cc9a93cae41f3262e00"

  let blakeAbc ← blake3 (bytes "abc")
  assertEq "blake3 abc length" blakeAbc.size 32
  expectHex "blake3 abc" blakeAbc
    "6437b3ac38465133ffb63b75273a8db548c558465d79db03fd359c6cd5bd9d85"

  let mac ← hmacSha256 hmacKey (bytes "Hi There")
  assertEq "hmac sha256 length" mac.size 32
  expectHex "hmac sha256 rfc4231 case 1" mac
    "b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7"

  for _ in [0:50] do
    expectHex "repeat sha256 abc" (← sha256 (bytes "abc"))
      "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
```

- [ ] **Step 2: Add the public Lean modules**

Replace `ZigLean.lean` with:

```lean
import ZigLean.Json
import ZigLean.Crypto
```

Create `ZigLean/Crypto.lean`:

```lean
import ZigLean.Crypto.Hash
```

Create `ZigLean/Crypto/Hash.lean`:

```lean
import ZigLean.Crypto.Hash.FFI

namespace ZigLean.Crypto.Hash

def sha256 (input : ByteArray) : IO ByteArray :=
  FFI.sha256Raw input

def blake3 (input : ByteArray) : IO ByteArray :=
  FFI.blake3Raw input

def hmacSha256 (key message : ByteArray) : IO ByteArray :=
  FFI.hmacSha256Raw key message

end ZigLean.Crypto.Hash
```

Create `ZigLean/Crypto/Hash/FFI.lean`:

```lean
namespace ZigLean.Crypto.Hash.FFI

@[extern "lean_ziglean_crypto_sha256"]
opaque sha256Raw : @& ByteArray -> IO ByteArray

@[extern "lean_ziglean_crypto_blake3"]
opaque blake3Raw : @& ByteArray -> IO ByteArray

@[extern "lean_ziglean_crypto_hmac_sha256"]
opaque hmacSha256Raw : @& ByteArray -> @& ByteArray -> IO ByteArray

end ZigLean.Crypto.Hash.FFI
```

- [ ] **Step 3: Add the crypto test executable**

In `lakefile.lean`, add this executable after `json_test`:

```lean
lean_exe crypto_hash_test where
  root := `CryptoHashTest
  srcDir := "test"
  supportInterpreter := true
```

- [ ] **Step 4: Run test to verify it fails**

Run: `lake exe crypto_hash_test`

Expected: FAIL at link time because the native C shim functions `lean_ziglean_crypto_sha256`, `lean_ziglean_crypto_blake3`, and `lean_ziglean_crypto_hmac_sha256` are not implemented yet.

- [ ] **Step 5: Commit**

```bash
git add ZigLean.lean ZigLean/Crypto.lean ZigLean/Crypto/Hash.lean ZigLean/Crypto/Hash/FFI.lean lakefile.lean test/CryptoHashTest.lean
git commit -m "Add Lean crypto hash API and tests"
```

---

### Task 2: Native Crypto Hash ABI and Implementation

**Files:**
- Create: `native/include/ziglean_crypto_hash.h`
- Create: `native/src/root.zig`
- Create: `native/src/crypto_hash.zig`
- Create: `native/c/lean_crypto_hash.c`
- Modify: `native/build.zig`
- Modify: `lakefile.lean`

**Interfaces:**
- Consumes:
  - Lean extern symbols from Task 1:
    - `lean_ziglean_crypto_sha256`
    - `lean_ziglean_crypto_blake3`
    - `lean_ziglean_crypto_hmac_sha256`
- Produces:
  - Zig C ABI:
    - `ziglean_crypto_sha256`
    - `ziglean_crypto_blake3`
    - `ziglean_crypto_hmac_sha256`

- [ ] **Step 1: Add the C ABI header**

Create `native/include/ziglean_crypto_hash.h`:

```c
#ifndef ZIGLEAN_CRYPTO_HASH_H
#define ZIGLEAN_CRYPTO_HASH_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

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

#ifdef __cplusplus
}
#endif

#endif
```

- [ ] **Step 2: Add the Zig crypto implementation**

Create `native/src/crypto_hash.zig`:

```zig
const std = @import("std");

export fn ziglean_crypto_sha256(input: [*]const u8, input_len: u64, out_digest: [*]u8) u32 {
    const bytes = input[0..@intCast(input_len)];
    const out: *[32]u8 = @ptrCast(out_digest);
    std.crypto.hash.sha2.Sha256.hash(bytes, out, .{});
    return 0;
}

export fn ziglean_crypto_blake3(input: [*]const u8, input_len: u64, out_digest: [*]u8) u32 {
    const bytes = input[0..@intCast(input_len)];
    const out = out_digest[0..32];
    std.crypto.hash.Blake3.hash(bytes, out, .{});
    return 0;
}

export fn ziglean_crypto_hmac_sha256(
    key: [*]const u8,
    key_len: u64,
    message: [*]const u8,
    message_len: u64,
    out_mac: [*]u8,
) u32 {
    const key_bytes = key[0..@intCast(key_len)];
    const message_bytes = message[0..@intCast(message_len)];
    const out: *[32]u8 = @ptrCast(out_mac);
    std.crypto.auth.hmac.sha2.HmacSha256.create(out, message_bytes, key_bytes);
    return 0;
}
```

- [ ] **Step 3: Add a native root module that imports JSON and crypto**

Create `native/src/root.zig`:

```zig
comptime {
    _ = @import("json.zig");
    _ = @import("crypto_hash.zig");
}
```

- [ ] **Step 4: Add the C shim**

Create `native/c/lean_crypto_hash.c`:

```c
#include <lean/lean.h>
#include <stdint.h>
#include "ziglean_crypto_hash.h"

static lean_obj_res mk_crypto_error(const char* message) {
  lean_object* str = lean_mk_string(message);
  lean_object* err = lean_mk_io_user_error(str);
  return lean_io_result_mk_error(err);
}

static lean_obj_res mk_digest_result(void) {
  return lean_alloc_sarray(1, ZIGLEAN_CRYPTO_SHA256_LEN, ZIGLEAN_CRYPTO_SHA256_LEN);
}

lean_obj_res lean_ziglean_crypto_sha256(b_lean_obj_arg input, lean_obj_arg world) {
  (void)world;
  size_t input_len = lean_sarray_size(input);
  const uint8_t* input_bytes = lean_sarray_cptr((lean_object*)input);
  lean_object* out = mk_digest_result();
  uint32_t status = ziglean_crypto_sha256(input_bytes, (uint64_t)input_len, lean_sarray_cptr(out));
  if (status != 0) {
    lean_dec(out);
    return mk_crypto_error("zig sha256 failed");
  }
  return lean_io_result_mk_ok(out);
}

lean_obj_res lean_ziglean_crypto_blake3(b_lean_obj_arg input, lean_obj_arg world) {
  (void)world;
  size_t input_len = lean_sarray_size(input);
  const uint8_t* input_bytes = lean_sarray_cptr((lean_object*)input);
  lean_object* out = mk_digest_result();
  uint32_t status = ziglean_crypto_blake3(input_bytes, (uint64_t)input_len, lean_sarray_cptr(out));
  if (status != 0) {
    lean_dec(out);
    return mk_crypto_error("zig blake3 failed");
  }
  return lean_io_result_mk_ok(out);
}

lean_obj_res lean_ziglean_crypto_hmac_sha256(
  b_lean_obj_arg key,
  b_lean_obj_arg message,
  lean_obj_arg world
) {
  (void)world;
  size_t key_len = lean_sarray_size(key);
  size_t message_len = lean_sarray_size(message);
  const uint8_t* key_bytes = lean_sarray_cptr((lean_object*)key);
  const uint8_t* message_bytes = lean_sarray_cptr((lean_object*)message);
  lean_object* out = mk_digest_result();
  uint32_t status = ziglean_crypto_hmac_sha256(
    key_bytes,
    (uint64_t)key_len,
    message_bytes,
    (uint64_t)message_len,
    lean_sarray_cptr(out)
  );
  if (status != 0) {
    lean_dec(out);
    return mk_crypto_error("zig hmac sha256 failed");
  }
  return lean_io_result_mk_ok(out);
}
```

- [ ] **Step 5: Update the native build**

In `native/build.zig`, change the root source file from `src/json.zig` to `src/root.zig`:

```zig
.root_source_file = b.path("src/root.zig"),
```

Then add the second C source file after the existing `lean_json.c` entry:

```zig
lib.root_module.addCSourceFile(.{
    .file = b.path("c/lean_crypto_hash.c"),
    .flags = &.{ "-std=c11", "-fno-sanitize=undefined" },
});
```

- [ ] **Step 6: Update Lake native dependencies**

In `lakefile.lean`, update the `extern_lib` dependency block so it tracks the new native files:

```lean
  let rootSrcJob ← inputFile (pkg.dir / "native" / "src" / "root.zig") true
  let zigSrcJob ← inputFile (pkg.dir / "native" / "src" / "json.zig") true
  let cryptoSrcJob ← inputFile (pkg.dir / "native" / "src" / "crypto_hash.zig") true
  let cSrcJob ← inputFile (pkg.dir / "native" / "c" / "lean_json.c") true
  let cryptoCSrcJob ← inputFile (pkg.dir / "native" / "c" / "lean_crypto_hash.c") true
  let hdrJob ← inputFile (pkg.dir / "native" / "include" / "ziglean_json.h") true
  let cryptoHdrJob ← inputFile (pkg.dir / "native" / "include" / "ziglean_crypto_hash.h") true
  let buildJob ← inputFile (pkg.dir / "native" / "build.zig") true
  let depJob :=
    buildJob.mix <|
      rootSrcJob.mix <|
        zigSrcJob.mix <|
          cryptoSrcJob.mix <|
            cSrcJob.mix <|
              cryptoCSrcJob.mix <|
                hdrJob.mix cryptoHdrJob
```

- [ ] **Step 7: Run crypto tests**

Run: `lake exe crypto_hash_test`

Expected: PASS.

- [ ] **Step 8: Run JSON regression tests**

Run: `lake exe json_test`

Expected: PASS.

- [ ] **Step 9: Commit**

```bash
git add native/include/ziglean_crypto_hash.h native/src/root.zig native/src/crypto_hash.zig native/c/lean_crypto_hash.c native/build.zig lakefile.lean
git commit -m "Implement Zig crypto hash native bindings"
```

---

### Task 3: Final Verification

**Files:**
- No source changes expected unless validation exposes a bug.

**Interfaces:**
- Consumes all previous tasks.
- Produces a clean repository with passing validators.

- [ ] **Step 1: Run JSON tests**

Run: `lake exe json_test`

Expected: PASS.

- [ ] **Step 2: Run crypto hash tests**

Run: `lake exe crypto_hash_test`

Expected: PASS.

- [ ] **Step 3: Run Lake build**

Run: `lake build`

Expected: PASS. The existing no-default-target warning is acceptable if the command exits 0.

- [ ] **Step 4: Run direct native build**

Run:

```bash
cd native && zig build -Dlean-prefix="$(lean --print-prefix)"
```

Expected: PASS.

- [ ] **Step 5: Check repository status**

Run: `git status --porcelain`

Expected: no tracked changes. Ignored build artifacts are acceptable.

- [ ] **Step 6: Handle validation failures**

If any validation command fails, stop Task 3 and create a focused fix task for the failing command. If all commands pass, do not create an empty commit.

---

## Self-Review Notes

- Spec coverage: public Lean APIs, C ABI, C shim, Zig std.crypto implementation, build integration, exact digest tests, repeated calls, and final validation are covered.
- Type consistency: `sha256`, `blake3`, `hmacSha256`, `sha256Raw`, `blake3Raw`, `hmacSha256Raw`, and C symbols use consistent names across tasks.
- Scope control: streaming contexts, keyed BLAKE3, random APIs, KDFs, signatures, compression, and async APIs remain outside this MVP.
