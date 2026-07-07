# Base32 Codec Extension Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add Base32 encode/decode to `ZigLean.Codec`.

**Architecture:** Reuse the existing Codec C ABI result struct and Lean `CodecError` type. Add Zig exports, C shim wrappers, Lean FFI declarations, and public API functions.

**Tech Stack:** Zig 0.16, Lean 4, Lake, C11.

## Global Constraints

- Zig output buffers must be allocated with `std.heap.c_allocator`.
- C shims must free Zig output buffers exactly once after copying.
- Lean extern names must match the C shim function names exactly.
- New native code must be registered in `native/src/root.zig`, `native/build.zig`, and `lakefile.lean` only if new files are added. This slice adds functions to existing files, so only the existing registration needs updating if a new native file is created.

---

### Task 1: Add Base32 Zig implementation

**Files:**
- Modify: `native/src/codec.zig`

**Interfaces:**
- Produces: `ziglean_codec_base32_encode`, `ziglean_codec_base32_decode`.

- [ ] **Step 1: Add Base32 functions to `native/src/codec.zig`**

After the existing Base64 functions, add:

```zig
fn encodeBase32(input: []const u8, out_result: *c.ZigLeanCodecResult) u32 {
    const encoder = std.base32.standard.Encoder;
    const out_len = encoder.calcSize(input.len);
    const out = allocBytes(out_len) catch return setError(out_result, STATUS_ALLOC);
    _ = encoder.encode(out, input);
    return setSuccess(out_result, out);
}

fn decodeBase32(input: []const u8, out_result: *c.ZigLeanCodecResult) u32 {
    const decoder = std.base32.standard.Decoder;
    const out_len = decoder.calcSizeForSlice(input) catch return setError(out_result, STATUS_INVALID_DATA);
    const out = allocBytes(out_len) catch return setError(out_result, STATUS_ALLOC);
    decoder.decode(out, input) catch |err| {
        std.heap.c_allocator.free(out);
        return switch (err) {
            error.InvalidPadding, error.InvalidCharacter => setError(out_result, STATUS_INVALID_DATA),
            error.NoSpaceLeft => setError(out_result, STATUS_ALLOC),
        };
    };
    return setSuccess(out_result, out);
}

export fn ziglean_codec_base32_encode(input: [*]const u8, input_len: u64, out_result: *c.ZigLeanCodecResult) u32 {
    return encodeBase32(input[0..@intCast(input_len)], out_result);
}

export fn ziglean_codec_base32_decode(input: [*]const u8, input_len: u64, out_result: *c.ZigLeanCodecResult) u32 {
    return decodeBase32(input[0..@intCast(input_len)], out_result);
}
```

- [ ] **Step 2: Verify `zig fmt src/codec.zig`**

Run: `cd native && zig fmt src/codec.zig`
Expected: no output (success).

- [ ] **Step 3: Commit**

```bash
git add native/src/codec.zig
git commit -m "feat(codec): add Base32 encode/decode in Zig"
```

---

### Task 2: Add Base32 C header declarations

**Files:**
- Modify: `native/include/ziglean_codec.h`

**Interfaces:**
- Produces: C declarations for `ziglean_codec_base32_encode` / `decode`.

- [ ] **Step 1: Add declarations after base58 declarations**

```c
uint32_t ziglean_codec_base32_encode(const uint8_t* input, uint64_t input_len, ZigLeanCodecResult* out_result);
uint32_t ziglean_codec_base32_decode(const uint8_t* input, uint64_t input_len, ZigLeanCodecResult* out_result);
```

- [ ] **Step 2: Commit**

```bash
git add native/include/ziglean_codec.h
git commit -m "feat(codec): declare Base32 functions in header"
```

---

### Task 3: Add Base32 C shim

**Files:**
- Modify: `native/c/lean_codec.c`

**Interfaces:**
- Produces: `lean_ziglean_codec_base32_encode`, `lean_ziglean_codec_base32_decode`.

- [ ] **Step 1: Add shim functions after base58 functions**

```c
lean_obj_res lean_ziglean_codec_base32_encode(b_lean_obj_arg input, lean_obj_arg world) {
  (void)world;
  ZigLeanCodecResult result = {0, 0, 0, 0, 0};
  (void)ziglean_codec_base32_encode(
    lean_sarray_cptr((lean_object*)input),
    (uint64_t)lean_sarray_size(input),
    &result
  );
  return copy_result_string(&result, "base32 encode failed");
}

lean_obj_res lean_ziglean_codec_base32_decode(b_lean_obj_arg input, lean_obj_arg world) {
  (void)world;
  ZigLeanCodecResult result = {0, 0, 0, 0, 0};
  size_t len = lean_string_size(input) - 1u;
  (void)ziglean_codec_base32_decode((const uint8_t*)lean_string_cstr(input), (uint64_t)len, &result);
  return copy_result_bytes(&result);
}
```

- [ ] **Step 2: Commit**

```bash
git add native/c/lean_codec.c
git commit -m "feat(codec): add Base32 C shim"
```

---

### Task 4: Add Base32 Lean FFI and public API

**Files:**
- Modify: `ZigLean/Codec/FFI.lean`
- Modify: `ZigLean/Codec.lean`

**Interfaces:**
- Consumes: `lean_ziglean_codec_base32_encode`, `lean_ziglean_codec_base32_decode`.
- Produces: `ZigLean.Codec.base32Encode`, `ZigLean.Codec.base32Decode`.

- [ ] **Step 1: Add FFI declarations to `ZigLean/Codec/FFI.lean`**

```lean
@[extern "lean_ziglean_codec_base32_encode"]
opaque base32EncodeRaw : @& ByteArray -> IO String

@[extern "lean_ziglean_codec_base32_decode"]
opaque base32DecodeRaw : @& String -> IO ByteArray
```

- [ ] **Step 2: Add public API to `ZigLean/Codec.lean`**

```lean
def base32Encode (input : ByteArray) : IO String :=
  FFI.base32EncodeRaw input

def base32Decode (input : String) : IO (Except CodecError ByteArray) := do
  pure <| decodeRawResult (← FFI.base32DecodeRaw input)
```

- [ ] **Step 3: Commit**

```bash
git add ZigLean/Codec/FFI.lean ZigLean/Codec.lean
git commit -m "feat(codec): add Lean Base32 API"
```

---

### Task 5: Add Base32 tests

**Files:**
- Modify: `test/CodecTest.lean`

**Interfaces:**
- Consumes: `ZigLean.Codec.base32Encode`, `ZigLean.Codec.base32Decode`.

- [ ] **Step 1: Add test cases to `CodecTest.main`**

After the base64url tests, add:

```lean
  assertEq "base32 encode empty" (← base32Encode ByteArray.empty) ""
  assertEq "base32 encode hello" (← base32Encode (bytes "hello")) "nbswy3dp"
  expectDecodeOk "base32 decode empty" (← base32Decode "") ByteArray.empty
  expectDecodeOk "base32 decode hello" (← base32Decode "nbswy3dp") (bytes "hello")
  expectDecodeError "base32 invalid char" (← base32Decode "nbswy3d!") 2 0
  expectDecodeError "base32 invalid padding" (← base32Decode "nbswy3d") 2 0
```

- [ ] **Step 2: Run `lake test`**

Expected: all suites pass, ending with `All tests passed.`

- [ ] **Step 3: Commit**

```bash
git add test/CodecTest.lean
git commit -m "test(codec): add Base32 encode/decode tests"
```

---

## Self-Review

**Spec coverage:**
- Base32 encode → Task 1, 4
- Base32 decode → Task 1, 4
- Tests → Task 5

**Placeholder scan:**
- No placeholders.

**Type consistency:**
- `lean_ziglean_codec_base32_*` names consistent across Zig, C header, C shim, and Lean FFI.
