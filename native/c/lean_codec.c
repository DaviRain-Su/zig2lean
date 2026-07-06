#include <lean/lean.h>
#include <stdint.h>
#include <string.h>
#include "ziglean_codec.h"

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

static lean_obj_res mk_codec_error(const char* message) {
  lean_object* str = lean_mk_string(message);
  lean_object* err = lean_mk_io_user_error(str);
  return lean_io_result_mk_error(err);
}

static lean_obj_res copy_result_bytes(ZigLeanCodecResult* result) {
  size_t out_len = 16u + (result->status == 0 ? (size_t)result->out_len : 0u);
  lean_object* out = lean_alloc_sarray(1, out_len, out_len);
  uint8_t* dst = lean_sarray_cptr(out);
  write_u32(dst, result->status);
  write_u32(dst + 4, result->status);
  write_u64(dst + 8, result->error_offset);
  if (result->status == 0 && result->out_len > 0) {
    memcpy(dst + 16, result->out, (size_t)result->out_len);
  }
  ziglean_codec_free(result->out, result->out_len);
  return lean_io_result_mk_ok(out);
}

static lean_obj_res copy_result_string(ZigLeanCodecResult* result, const char* message) {
  if (result->status != 0) {
    ziglean_codec_free(result->out, result->out_len);
    return mk_codec_error(message);
  }
  lean_object* out = lean_mk_string_from_bytes((const char*)result->out, (size_t)result->out_len);
  ziglean_codec_free(result->out, result->out_len);
  return lean_io_result_mk_ok(out);
}

lean_obj_res lean_ziglean_codec_hex_encode_lower(b_lean_obj_arg input, lean_obj_arg world) {
  (void)world;
  ZigLeanCodecResult result = {0, 0, 0, 0, 0};
  uint32_t status = ziglean_codec_hex_encode_lower(
    lean_sarray_cptr((lean_object*)input),
    (uint64_t)lean_sarray_size(input),
    &result
  );
  (void)status;
  return copy_result_string(&result, "hex encode failed");
}

lean_obj_res lean_ziglean_codec_hex_decode(b_lean_obj_arg input, lean_obj_arg world) {
  (void)world;
  ZigLeanCodecResult result = {0, 0, 0, 0, 0};
  size_t len = lean_string_size(input) - 1u;
  (void)ziglean_codec_hex_decode((const uint8_t*)lean_string_cstr(input), (uint64_t)len, &result);
  return copy_result_bytes(&result);
}

lean_obj_res lean_ziglean_codec_base64_encode(b_lean_obj_arg input, lean_obj_arg world) {
  (void)world;
  ZigLeanCodecResult result = {0, 0, 0, 0, 0};
  (void)ziglean_codec_base64_encode(
    lean_sarray_cptr((lean_object*)input),
    (uint64_t)lean_sarray_size(input),
    &result
  );
  return copy_result_string(&result, "base64 encode failed");
}

lean_obj_res lean_ziglean_codec_base64_decode(b_lean_obj_arg input, lean_obj_arg world) {
  (void)world;
  ZigLeanCodecResult result = {0, 0, 0, 0, 0};
  size_t len = lean_string_size(input) - 1u;
  (void)ziglean_codec_base64_decode((const uint8_t*)lean_string_cstr(input), (uint64_t)len, &result);
  return copy_result_bytes(&result);
}

lean_obj_res lean_ziglean_codec_base64url_encode(b_lean_obj_arg input, lean_obj_arg world) {
  (void)world;
  ZigLeanCodecResult result = {0, 0, 0, 0, 0};
  (void)ziglean_codec_base64url_encode(
    lean_sarray_cptr((lean_object*)input),
    (uint64_t)lean_sarray_size(input),
    &result
  );
  return copy_result_string(&result, "base64url encode failed");
}

lean_obj_res lean_ziglean_codec_base64url_decode(b_lean_obj_arg input, lean_obj_arg world) {
  (void)world;
  ZigLeanCodecResult result = {0, 0, 0, 0, 0};
  size_t len = lean_string_size(input) - 1u;
  (void)ziglean_codec_base64url_decode((const uint8_t*)lean_string_cstr(input), (uint64_t)len, &result);
  return copy_result_bytes(&result);
}

lean_obj_res lean_ziglean_codec_base58_encode(b_lean_obj_arg input, lean_obj_arg world) {
  (void)world;
  ZigLeanCodecResult result = {0, 0, 0, 0, 0};
  (void)ziglean_codec_base58_encode(
    lean_sarray_cptr((lean_object*)input),
    (uint64_t)lean_sarray_size(input),
    &result
  );
  return copy_result_string(&result, "base58 encode failed");
}

lean_obj_res lean_ziglean_codec_base58_decode(b_lean_obj_arg input, lean_obj_arg world) {
  (void)world;
  ZigLeanCodecResult result = {0, 0, 0, 0, 0};
  size_t len = lean_string_size(input) - 1u;
  (void)ziglean_codec_base58_decode((const uint8_t*)lean_string_cstr(input), (uint64_t)len, &result);
  return copy_result_bytes(&result);
}
