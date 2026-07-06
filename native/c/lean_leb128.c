#include <lean/lean.h>
#include <stdint.h>
#include <string.h>
#include "ziglean_leb128.h"

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

static lean_obj_res mk_leb128_error(const char* message) {
  lean_object* str = lean_mk_string(message);
  lean_object* err = lean_mk_io_user_error(str);
  return lean_io_result_mk_error(err);
}

static lean_obj_res copy_encode_output(ZigLeanLeb128Result* result, const char* message) {
  if (result->status != 0) {
    ziglean_leb128_free(result->out, result->out_len);
    return mk_leb128_error(message);
  }
  lean_object* out = lean_alloc_sarray(1, (size_t)result->out_len, (size_t)result->out_len);
  if (result->out_len > 0) {
    memcpy(lean_sarray_cptr(out), result->out, (size_t)result->out_len);
  }
  ziglean_leb128_free(result->out, result->out_len);
  return lean_io_result_mk_ok(out);
}

static lean_obj_res copy_decode_result(ZigLeanLeb128Result* result) {
  lean_object* out = lean_alloc_sarray(1, 24, 24);
  uint8_t* dst = lean_sarray_cptr(out);
  write_u32(dst, result->status);
  write_u32(dst + 4, result->status);
  write_u64(dst + 8, result->value);
  write_u64(dst + 16, 0);
  return lean_io_result_mk_ok(out);
}

lean_obj_res lean_ziglean_leb128_encode_u64(uint64_t value, lean_obj_arg world) {
  (void)world;
  ZigLeanLeb128Result result = {0, 0, 0, 0, 0};
  (void)ziglean_leb128_encode_u64(value, &result);
  return copy_encode_output(&result, "uleb128 encode failed");
}

lean_obj_res lean_ziglean_leb128_decode_u64(b_lean_obj_arg input, lean_obj_arg world) {
  (void)world;
  ZigLeanLeb128Result result = {0, 0, 0, 0, 0};
  (void)ziglean_leb128_decode_u64(
    lean_sarray_cptr((lean_object*)input),
    (uint64_t)lean_sarray_size(input),
    &result
  );
  return copy_decode_result(&result);
}

lean_obj_res lean_ziglean_leb128_encode_i64(int64_t value, lean_obj_arg world) {
  (void)world;
  ZigLeanLeb128Result result = {0, 0, 0, 0, 0};
  (void)ziglean_leb128_encode_i64(value, &result);
  return copy_encode_output(&result, "sleb128 encode failed");
}

lean_obj_res lean_ziglean_leb128_decode_i64(b_lean_obj_arg input, lean_obj_arg world) {
  (void)world;
  ZigLeanLeb128Result result = {0, 0, 0, 0, 0};
  (void)ziglean_leb128_decode_i64(
    lean_sarray_cptr((lean_object*)input),
    (uint64_t)lean_sarray_size(input),
    &result
  );
  return copy_decode_result(&result);
}