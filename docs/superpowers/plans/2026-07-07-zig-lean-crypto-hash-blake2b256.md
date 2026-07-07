# Blake2b-256 Extension Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add Blake2b-256 to `ZigLean.Crypto.Hash`.

**Architecture:** Reuse the existing digest C ABI pattern.

**Tech Stack:** Zig 0.16, Lean 4, Lake, C11.

## Global Constraints

- Zig writes the 32-byte digest to the caller-provided pointer.
- C shims allocate a Lean `ByteArray` of length 32 and copy the digest.
- Lean extern names must match the C shim function names exactly.

---

### Task 1: Add Blake2b-256 Zig implementation

**Files:**
- Modify: `native/src/crypto_hash.zig`

- [ ] **Step 1: Add function**

```zig
export fn ziglean_crypto_blake2b256(input: [*]const u8, input_len: u64, out_digest: [*]u8) u32 {
    const bytes = input[0..@intCast(input_len)];
    const out = out_digest[0..32];
    std.crypto.hash.blake2.Blake2b256.hash(bytes, out, .{});
    return 0;
}
```

- [ ] **Step 2: Verify `zig fmt src/crypto_hash.zig`**

- [ ] **Step 3: Commit**

```bash
git add native/src/crypto_hash.zig
git commit -m "feat(crypto): add Blake2b-256 in Zig"
```

---

### Task 2: Add Blake2b-256 C header declaration

**Files:**
- Modify: `native/include/ziglean_crypto_hash.h`

- [ ] **Step 1: Add macro and declaration**

```c
#define ZIGLEAN_CRYPTO_BLAKE2B256_LEN 32

uint32_t ziglean_crypto_blake2b256(
  const uint8_t* input,
  uint64_t input_len,
  uint8_t* out_digest
);
```

- [ ] **Step 2: Commit**

```bash
git add native/include/ziglean_crypto_hash.h
git commit -m "feat(crypto): declare Blake2b-256 in header"
```

---

### Task 3: Add Blake2b-256 C shim

**Files:**
- Modify: `native/c/lean_crypto_hash.c`

- [ ] **Step 1: Add shim function**

```c
lean_obj_res lean_ziglean_crypto_blake2b256(b_lean_obj_arg input, lean_obj_arg world) {
  (void)world;
  size_t input_len = lean_sarray_size(input);
  const uint8_t* input_bytes = lean_sarray_cptr((lean_object*)input);
  lean_object* out = mk_digest_result(ZIGLEAN_CRYPTO_BLAKE2B256_LEN);
  uint32_t status = ziglean_crypto_blake2b256(input_bytes, (uint64_t)input_len, lean_sarray_cptr(out));
  if (status != 0) {
    lean_dec(out);
    return mk_crypto_error("zig blake2b256 failed");
  }
  return lean_io_result_mk_ok(out);
}
```

- [ ] **Step 2: Commit**

```bash
git add native/c/lean_crypto_hash.c
git commit -m "feat(crypto): add Blake2b-256 C shim"
```

---

### Task 4: Add Blake2b-256 Lean FFI and public API

**Files:**
- Modify: `ZigLean/Crypto/Hash/FFI.lean`
- Modify: `ZigLean/Crypto/Hash.lean`

- [ ] **Step 1: Add FFI declaration**

```lean
@[extern "lean_ziglean_crypto_blake2b256"]
opaque blake2b256Raw : @& ByteArray -> IO ByteArray
```

- [ ] **Step 2: Add public API**

```lean
def blake2b256 (input : ByteArray) : IO ByteArray :=
  FFI.blake2b256Raw input
```

- [ ] **Step 3: Commit**

```bash
git add ZigLean/Crypto/Hash/FFI.lean ZigLean/Crypto/Hash.lean
git commit -m "feat(crypto): add Lean Blake2b-256 API"
```

---

### Task 5: Add Blake2b-256 tests

**Files:**
- Modify: `test/CryptoHashTest.lean`

- [ ] **Step 1: Add test cases**

```lean
  let b2 ← blake2b256 ByteArray.empty
  assertEq "blake2b256 empty length" b2.size 32
  expectHex "blake2b256 empty" b2
    "0e5751c026e543b2e8ab2eb06099daa1d1e5df47778f7787faab45cdf12fe3a8"
```

- [ ] **Step 2: Run `lake test`**

- [ ] **Step 3: Commit**

```bash
git add test/CryptoHashTest.lean
git commit -m "test(crypto): add Blake2b-256 tests"
```

---

## Self-Review

**Spec coverage:**
- Blake2b-256 one-shot API → Tasks 1-4
- Tests → Task 5

**Placeholder scan:**
- No placeholders.

**Type consistency:**
- `lean_ziglean_crypto_blake2b256` consistent across all layers.
