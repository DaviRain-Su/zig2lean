# Adler32 Checksum Extension Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add Adler32 checksum to `ZigLean.Hash.Checksum`.

**Architecture:** Reuse the existing checksum C ABI pattern. Add a Zig export, C header declaration, C shim, Lean FFI declaration, and public API function.

**Tech Stack:** Zig 0.16, Lean 4, Lake, C11.

## Global Constraints

- Zig output must be written to the caller-provided pointer.
- C shims must return `IO UInt32` via `lean_box_uint32`.
- Lean extern names must match the C shim function names exactly.

---

### Task 1: Add Adler32 Zig implementation

**Files:**
- Modify: `native/src/hash_checksum.zig`

**Interfaces:**
- Produces: `ziglean_hash_adler32(input, input_len, out_adler) -> u32`.

- [ ] **Step 1: Add function to `native/src/hash_checksum.zig`**

After `ziglean_hash_crc32`, add:

```zig
export fn ziglean_hash_adler32(input: [*]const u8, input_len: u64, out_adler: *u32) u32 {
    var adler = std.hash.Adler32.init();
    adler.update(input[0..@intCast(input_len)]);
    out_adler.* = adler.final();
    return 0;
}
```

- [ ] **Step 2: Verify `zig fmt src/hash_checksum.zig`**

- [ ] **Step 3: Commit**

```bash
git add native/src/hash_checksum.zig
git commit -m "feat(hash): add Adler32 checksum in Zig"
```

---

### Task 2: Add Adler32 C header declaration

**Files:**
- Modify: `native/include/ziglean_hash_checksum.h`

- [ ] **Step 1: Add declaration**

```c
uint32_t ziglean_hash_adler32(const uint8_t* input, uint64_t input_len, uint32_t* out_adler);
```

- [ ] **Step 2: Commit**

```bash
git add native/include/ziglean_hash_checksum.h
git commit -m "feat(hash): declare Adler32 function in header"
```

---

### Task 3: Add Adler32 C shim

**Files:**
- Modify: `native/c/lean_hash_checksum.c`

- [ ] **Step 1: Add shim function**

```c
lean_obj_res lean_ziglean_hash_adler32(b_lean_obj_arg input, lean_obj_arg world) {
  (void)world;
  uint32_t adler = 0;
  uint32_t status = ziglean_hash_adler32(
    lean_sarray_cptr((lean_object*)input),
    (uint64_t)lean_sarray_size(input),
    &adler
  );
  if (status != 0) {
    return mk_checksum_error("adler32 failed");
  }
  return lean_io_result_mk_ok(lean_box_uint32(adler));
}
```

- [ ] **Step 2: Commit**

```bash
git add native/c/lean_hash_checksum.c
git commit -m "feat(hash): add Adler32 C shim"
```

---

### Task 4: Add Adler32 Lean FFI and public API

**Files:**
- Modify: `ZigLean/Hash/Checksum/FFI.lean`
- Modify: `ZigLean/Hash/Checksum.lean`

- [ ] **Step 1: Add FFI declaration**

```lean
@[extern "lean_ziglean_hash_adler32"]
opaque adler32Raw : @& ByteArray -> IO UInt32
```

- [ ] **Step 2: Add public API**

```lean
def adler32 (input : ByteArray) : IO UInt32 :=
  FFI.adler32Raw input
```

- [ ] **Step 3: Commit**

```bash
git add ZigLean/Hash/Checksum/FFI.lean ZigLean/Hash/Checksum.lean
git commit -m "feat(hash): add Lean Adler32 API"
```

---

### Task 5: Add Adler32 tests

**Files:**
- Modify: `test/CryptoExtendedTest.lean`

- [ ] **Step 1: Add test cases**

After the crc32 test, add:

```lean
  assertEq "adler32 empty" (← adler32 ByteArray.empty) 1
  assertEq "adler32 123456789" (← adler32 (bytes "123456789")) 0x091e01de
```

- [ ] **Step 2: Run `lake test`**

Expected: all suites pass.

- [ ] **Step 3: Commit**

```bash
git add test/CryptoExtendedTest.lean
git commit -m "test(hash): add Adler32 tests"
```

---

## Self-Review

**Spec coverage:**
- Adler32 one-shot API → Tasks 1-4
- Tests → Task 5

**Placeholder scan:**
- No placeholders.

**Type consistency:**
- `lean_ziglean_hash_adler32` consistent across all layers.
