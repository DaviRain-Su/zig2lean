# CRC32C Extension Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add CRC32C to `ZigLean.Hash.Checksum`.

**Architecture:** Reuse the existing checksum C ABI pattern.

**Tech Stack:** Zig 0.16, Lean 4, Lake, C11.

## Global Constraints

- Zig writes the 32-bit CRC to the caller-provided pointer.
- C shims return `IO UInt32` via `lean_box_uint32`.
- Lean extern names must match the C shim function names exactly.

---

### Task 1: Add CRC32C Zig implementation

**Files:**
- Modify: `native/src/hash_checksum.zig`

- [ ] **Step 1: Add function after `ziglean_hash_crc32`**

```zig
export fn ziglean_hash_crc32c(input: [*]const u8, input_len: u64, out_crc: *u32) u32 {
    var crc = std.hash.crc.Crc32Iscsi.init();
    crc.update(input[0..@intCast(input_len)]);
    out_crc.* = crc.final();
    return 0;
}
```

- [ ] **Step 2: Verify `zig fmt src/hash_checksum.zig`**

- [ ] **Step 3: Commit**

```bash
git add native/src/hash_checksum.zig
git commit -m "feat(hash): add CRC32C in Zig"
```

---

### Task 2: Add CRC32C C header declaration

**Files:**
- Modify: `native/include/ziglean_hash_checksum.h`

- [ ] **Step 1: Add declaration**

```c
uint32_t ziglean_hash_crc32c(const uint8_t* input, uint64_t input_len, uint32_t* out_crc);
```

- [ ] **Step 2: Commit**

```bash
git add native/include/ziglean_hash_checksum.h
git commit -m "feat(hash): declare CRC32C in header"
```

---

### Task 3: Add CRC32C C shim

**Files:**
- Modify: `native/c/lean_hash_checksum.c`

- [ ] **Step 1: Add shim function after `lean_ziglean_hash_crc32`**

```c
lean_obj_res lean_ziglean_hash_crc32c(b_lean_obj_arg input, lean_obj_arg world) {
  (void)world;
  uint32_t crc = 0;
  uint32_t status = ziglean_hash_crc32c(
    lean_sarray_cptr((lean_object*)input),
    (uint64_t)lean_sarray_size(input),
    &crc
  );
  if (status != 0) {
    return mk_checksum_error("crc32c failed");
  }
  return lean_io_result_mk_ok(lean_box_uint32(crc));
}
```

- [ ] **Step 2: Commit**

```bash
git add native/c/lean_hash_checksum.c
git commit -m "feat(hash): add CRC32C C shim"
```

---

### Task 4: Add CRC32C Lean FFI and public API

**Files:**
- Modify: `ZigLean/Hash/Checksum/FFI.lean`
- Modify: `ZigLean/Hash/Checksum.lean`

- [ ] **Step 1: Add FFI declaration**

```lean
@[extern "lean_ziglean_hash_crc32c"]
opaque crc32cRaw : @& ByteArray -> IO UInt32
```

- [ ] **Step 2: Add public API**

```lean
def crc32c (input : ByteArray) : IO UInt32 :=
  FFI.crc32cRaw input
```

- [ ] **Step 3: Commit**

```bash
git add ZigLean/Hash/Checksum/FFI.lean ZigLean/Hash/Checksum.lean
git commit -m "feat(hash): add Lean CRC32C API"
```

---

### Task 5: Add CRC32C tests

**Files:**
- Modify: `test/CryptoExtendedTest.lean`

- [ ] **Step 1: Add test cases**

After the crc32 test:

```lean
  let crcC ← crc32c (bytes "123456789")
  assertEq "crc32c" crcC 0xe3069283
```

- [ ] **Step 2: Run `lake test`**

- [ ] **Step 3: Commit**

```bash
git add test/CryptoExtendedTest.lean
git commit -m "test(hash): add CRC32C tests"
```

---

## Self-Review

**Spec coverage:**
- CRC32C one-shot API → Tasks 1-4
- Tests → Task 5

**Placeholder scan:**
- No placeholders.

**Type consistency:**
- `lean_ziglean_hash_crc32c` consistent across all layers.
