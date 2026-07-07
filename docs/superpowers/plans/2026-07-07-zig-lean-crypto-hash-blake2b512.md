# Blake2b-512 Extension Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add Blake2b-512 to `ZigLean.Crypto.Hash`.

**Architecture:** Reuse the existing digest C ABI pattern.

**Tech Stack:** Zig 0.16, Lean 4, Lake, C11.

## Global Constraints

- Zig writes the 64-byte digest to the caller-provided pointer.
- C shims allocate a Lean `ByteArray` of length 64 and copy the digest.
- Lean extern names must match the C shim function names exactly.

---

### Task 1: Add Blake2b-512 Zig implementation

**Files:**
- Modify: `native/src/crypto_hash.zig`

- [ ] **Step 1: Add function**

```zig
export fn ziglean_crypto_blake2b512(input: [*]const u8, input_len: u64, out_digest: [*]u8) u32 {
    const bytes = input[0..@intCast(input_len)];
    const out = out_digest[0..64];
    std.crypto.hash.blake2.Blake2b512.hash(bytes, out, .{});
    return 0;
}
```

- [ ] **Step 2: Verify `zig fmt src/crypto_hash.zig`**

- [ ] **Step 3: Commit**

```bash
git add native/src/crypto_hash.zig
git commit -m "feat(crypto): add Blake2b-512 in Zig"
```

---

### Task 2: Add Blake2b-512 C header declaration

**Files:**
- Modify: `native/include/ziglean_crypto_hash.h`

- [ ] **Step 1: Add macro and declaration**

```c
#define ZIGLEAN_CRYPTO_BLAKE2B512_LEN 64

uint32_t ziglean_crypto_blake2b512(
  const uint8_t* input,
  uint64_t input_len,
  uint8_t* out_digest
);
```

- [ ] **Step 2: Commit**

```bash
git add native/include/ziglean_crypto_hash.h
git commit -m "feat(crypto): declare Blake2b-512 in header"
```

---

### Task 3: Add Blake2b-512 C shim

**Files:**
- Modify: `native/c/lean_crypto_hash.c`

- [ ] **Step 1: Add shim function**

```c
lean_obj_res lean_ziglean_crypto_blake2b512(b_lean_obj_arg input, lean_obj_arg world) {
  (void)world;
  size_t input_len = lean_sarray_size(input);
  const uint8_t* input_bytes = lean_sarray_cptr((lean_object*)input);
  lean_object* out = mk_digest_result(ZIGLEAN_CRYPTO_BLAKE2B512_LEN);
  uint32_t status = ziglean_crypto_blake2b512(input_bytes, (uint64_t)input_len, lean_sarray_cptr(out));
  if (status != 0) {
    lean_dec(out);
    return mk_crypto_error("zig blake2b512 failed");
  }
  return lean_io_result_mk_ok(out);
}
```

- [ ] **Step 2: Commit**

```bash
git add native/c/lean_crypto_hash.c
git commit -m "feat(crypto): add Blake2b-512 C shim"
```

---

### Task 4: Add Blake2b-512 Lean FFI and public API

**Files:**
- Modify: `ZigLean/Crypto/Hash/FFI.lean`
- Modify: `ZigLean/Crypto/Hash.lean`

- [ ] **Step 1: Add FFI declaration**

```lean
@[extern "lean_ziglean_crypto_blake2b512"]
opaque blake2b512Raw : @& ByteArray -> IO ByteArray
```

- [ ] **Step 2: Add public API**

```lean
def blake2b512 (input : ByteArray) : IO ByteArray :=
  FFI.blake2b512Raw input
```

- [ ] **Step 3: Commit**

```bash
git add ZigLean/Crypto/Hash/FFI.lean ZigLean/Crypto/Hash.lean
git commit -m "feat(crypto): add Lean Blake2b-512 API"
```

---

### Task 5: Add Blake2b-512 tests

**Files:**
- Modify: `test/CryptoHashTest.lean`

- [ ] **Step 1: Add test case**

```lean
  let b2_512_empty ← blake2b512 ByteArray.empty
  assertEq "blake2b512 empty length" b2_512_empty.size 64
  expectHex "blake2b512 empty" b2_512_empty
    "786a02f742015903c6c6fd852552d272912f4740e15847618a86e217f71f5419d25e1031afee585313896444934eb04b903a685b1448b755d56f701afe9be2ce"
```

- [ ] **Step 2: Run `lake test`**

- [ ] **Step 3: Commit**

```bash
git add test/CryptoHashTest.lean
git commit -m "test(crypto): add Blake2b-512 tests"
```

---

## Self-Review

**Spec coverage:**
- Blake2b-512 one-shot API → Tasks 1-4
- Tests → Task 5

**Placeholder scan:**
- No placeholders.

**Type consistency:**
- `lean_ziglean_crypto_blake2b512` consistent across all layers.
