# HMAC-SHA512 Extension Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add HMAC-SHA512 to `ZigLean.Crypto.Hash`.

**Architecture:** Reuse the existing digest C ABI pattern. Add a Zig export, C header declaration, C shim, Lean FFI declaration, and public API function.

**Tech Stack:** Zig 0.16, Lean 4, Lake, C11.

## Global Constraints

- Zig writes the 64-byte digest to the caller-provided pointer.
- C shims allocate a Lean `ByteArray` of length 64 and copy the digest.
- Lean extern names must match the C shim function names exactly.

---

### Task 1: Add HMAC-SHA512 Zig implementation

**Files:**
- Modify: `native/src/crypto_hash.zig`

**Interfaces:**
- Produces: `ziglean_crypto_hmac_sha512(key, key_len, message, message_len, out_mac) -> u32`.

- [ ] **Step 1: Add function after `ziglean_crypto_hmac_sha256`**

```zig
export fn ziglean_crypto_hmac_sha512(
    key: [*]const u8,
    key_len: u64,
    message: [*]const u8,
    message_len: u64,
    out_mac: [*]u8,
) u32 {
    const key_bytes = key[0..@intCast(key_len)];
    const message_bytes = message[0..@intCast(message_len)];
    const out: *[64]u8 = @ptrCast(out_mac);
    std.crypto.auth.hmac.sha2.HmacSha512.create(out, message_bytes, key_bytes);
    return 0;
}
```

- [ ] **Step 2: Verify `zig fmt src/crypto_hash.zig`**

- [ ] **Step 3: Commit**

```bash
git add native/src/crypto_hash.zig
git commit -m "feat(crypto): add HMAC-SHA512 in Zig"
```

---

### Task 2: Add HMAC-SHA512 C header declaration

**Files:**
- Modify: `native/include/ziglean_crypto_hash.h`

- [ ] **Step 1: Add length macro and declaration**

```c
#define ZIGLEAN_CRYPTO_HMAC_SHA512_LEN 64

uint32_t ziglean_crypto_hmac_sha512(
  const uint8_t* key,
  uint64_t key_len,
  const uint8_t* message,
  uint64_t message_len,
  uint8_t* out_mac
);
```

- [ ] **Step 2: Commit**

```bash
git add native/include/ziglean_crypto_hash.h
git commit -m "feat(crypto): declare HMAC-SHA512 in header"
```

---

### Task 3: Add HMAC-SHA512 C shim

**Files:**
- Modify: `native/c/lean_crypto_hash.c`

- [ ] **Step 1: Add shim function after HMAC-SHA256**

```c
lean_obj_res lean_ziglean_crypto_hmac_sha512(
  b_lean_obj_arg key,
  b_lean_obj_arg message,
  lean_obj_arg world
) {
  (void)world;
  size_t key_len = lean_sarray_size(key);
  size_t message_len = lean_sarray_size(message);
  const uint8_t* key_bytes = lean_sarray_cptr((lean_object*)key);
  const uint8_t* message_bytes = lean_sarray_cptr((lean_object*)message);
  lean_object* out = mk_digest_result(ZIGLEAN_CRYPTO_HMAC_SHA512_LEN);
  uint32_t status = ziglean_crypto_hmac_sha512(
    key_bytes,
    (uint64_t)key_len,
    message_bytes,
    (uint64_t)message_len,
    lean_sarray_cptr(out)
  );
  if (status != 0) {
    lean_dec(out);
    return mk_crypto_error("zig hmac sha512 failed");
  }
  return lean_io_result_mk_ok(out);
}
```

- [ ] **Step 2: Commit**

```bash
git add native/c/lean_crypto_hash.c
git commit -m "feat(crypto): add HMAC-SHA512 C shim"
```

---

### Task 4: Add HMAC-SHA512 Lean FFI and public API

**Files:**
- Modify: `ZigLean/Crypto/Hash/FFI.lean`
- Modify: `ZigLean/Crypto/Hash.lean`

- [ ] **Step 1: Add FFI declaration**

```lean
@[extern "lean_ziglean_crypto_hmac_sha512"]
opaque hmacSha512Raw : @& ByteArray -> @& ByteArray -> IO ByteArray
```

- [ ] **Step 2: Add public API**

```lean
def hmacSha512 (key message : ByteArray) : IO ByteArray :=
  FFI.hmacSha512Raw key message
```

- [ ] **Step 3: Commit**

```bash
git add ZigLean/Crypto/Hash/FFI.lean ZigLean/Crypto/Hash.lean
git commit -m "feat(crypto): add Lean HMAC-SHA512 API"
```

---

### Task 5: Add HMAC-SHA512 tests

**Files:**
- Modify: `test/CryptoHashTest.lean`

- [ ] **Step 1: Add test cases**

After the HMAC-SHA256 tests, add:

```lean
  let hmac512 ← hmacSha256 (bytes "key") (bytes "The quick brown fox jumps over the lazy dog")
  assertEq "hmac sha512 length" hmac512.size 64
```

Wait, use `hmacSha512`. Add a known-vector test if available.

```lean
  let hmac512 ← hmacSha512 (bytes "key") (bytes "The quick brown fox jumps over the lazy dog")
  assertEq "hmac sha512 length" hmac512.size 64
```

- [ ] **Step 2: Run `lake test`**

Expected: all suites pass.

- [ ] **Step 3: Commit**

```bash
git add test/CryptoHashTest.lean
git commit -m "test(crypto): add HMAC-SHA512 tests"
```

---

## Self-Review

**Spec coverage:**
- HMAC-SHA512 one-shot API → Tasks 1-4
- Tests → Task 5

**Placeholder scan:**
- No placeholders.

**Type consistency:**
- `lean_ziglean_crypto_hmac_sha512` consistent across all layers.
