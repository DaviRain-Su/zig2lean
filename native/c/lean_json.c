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
