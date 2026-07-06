#include <lean/lean.h>
#include <stdint.h>
#include <string.h>
#include "ziglean_compress.h"

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

static lean_obj_res mk_compress_error(const char* message) {
  lean_object* str = lean_mk_string(message);
  lean_object* err = lean_mk_io_user_error(str);
  return lean_io_result_mk_error(err);
}

static lean_obj_res copy_result_bytes(ZigLeanCompressResult* result) {
  size_t out_len = 16u + (result->status == 0 ? (size_t)result->out_len : 0u);
  lean_object* out = lean_alloc_sarray(1, out_len, out_len);
  uint8_t* dst = lean_sarray_cptr(out);
  write_u32(dst, result->status);
  write_u32(dst + 4, result->status);
  write_u64(dst + 8, result->error_offset);
  if (result->status == 0 && result->out_len > 0) {
    memcpy(dst + 16, result->out, (size_t)result->out_len);
  }
  ziglean_compress_free(result->out, result->out_len);
  return lean_io_result_mk_ok(out);
}

static lean_obj_res copy_compress_output(ZigLeanCompressResult* result, const char* message) {
  if (result->status != 0) {
    ziglean_compress_free(result->out, result->out_len);
    return mk_compress_error(message);
  }
  lean_object* out = lean_alloc_sarray(1, (size_t)result->out_len, (size_t)result->out_len);
  if (result->out_len > 0) {
    memcpy(lean_sarray_cptr(out), result->out, (size_t)result->out_len);
  }
  ziglean_compress_free(result->out, result->out_len);
  return lean_io_result_mk_ok(out);
}

#define DEFINE_COMPRESS_FN(lean_name, zig_name, err_msg) \
  lean_obj_res lean_name(b_lean_obj_arg input, lean_obj_arg world) { \
    (void)world; \
    ZigLeanCompressResult result = {0, 0, 0, 0, 0}; \
    (void)zig_name( \
      lean_sarray_cptr((lean_object*)input), \
      (uint64_t)lean_sarray_size(input), \
      &result \
    ); \
    return copy_compress_output(&result, err_msg); \
  }

#define DEFINE_DECOMPRESS_FN(lean_name, zig_name) \
  lean_obj_res lean_name(b_lean_obj_arg input, lean_obj_arg world) { \
    (void)world; \
    ZigLeanCompressResult result = {0, 0, 0, 0, 0}; \
    (void)zig_name( \
      lean_sarray_cptr((lean_object*)input), \
      (uint64_t)lean_sarray_size(input), \
      &result \
    ); \
    return copy_result_bytes(&result); \
  }

DEFINE_COMPRESS_FN(lean_ziglean_compress_gzip, ziglean_compress_gzip, "gzip compress failed")
DEFINE_DECOMPRESS_FN(lean_ziglean_compress_gzip_decompress, ziglean_compress_gzip_decompress)
DEFINE_COMPRESS_FN(lean_ziglean_compress_zlib, ziglean_compress_zlib, "zlib compress failed")
DEFINE_DECOMPRESS_FN(lean_ziglean_compress_zlib_decompress, ziglean_compress_zlib_decompress)
DEFINE_COMPRESS_FN(lean_ziglean_compress_deflate, ziglean_compress_deflate, "deflate compress failed")
DEFINE_DECOMPRESS_FN(lean_ziglean_compress_deflate_decompress, ziglean_compress_deflate_decompress)