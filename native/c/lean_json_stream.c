#include <lean/lean.h>
#include <stdint.h>
#include <string.h>
#include "ziglean_json_stream.h"

static lean_obj_res mk_json_stream_error(const char* message) {
  lean_object* str = lean_mk_string(message);
  lean_object* err = lean_mk_io_user_error(str);
  return lean_io_result_mk_error(err);
}

static lean_obj_res mk_stream_result(const ZigLeanJsonStreamResult* result) {
  lean_object* out = lean_alloc_sarray(1, 32, 32);
  uint8_t* dst = lean_sarray_cptr(out);
  dst[0] = (uint8_t)(result->status & 0xffu);
  dst[1] = (uint8_t)((result->status >> 8) & 0xffu);
  dst[2] = (uint8_t)((result->status >> 16) & 0xffu);
  dst[3] = (uint8_t)((result->status >> 24) & 0xffu);
  dst[4] = (uint8_t)(result->kind & 0xffu);
  dst[5] = (uint8_t)((result->kind >> 8) & 0xffu);
  dst[6] = (uint8_t)((result->kind >> 16) & 0xffu);
  dst[7] = (uint8_t)((result->kind >> 24) & 0xffu);
  for (uint32_t i = 0; i < 8; i++) {
    dst[8 + i] = (uint8_t)((result->offset >> (8u * i)) & 0xffu);
    dst[16 + i] = (uint8_t)((result->length >> (8u * i)) & 0xffu);
    dst[24 + i] = (uint8_t)((result->error_offset >> (8u * i)) & 0xffu);
  }
  return lean_io_result_mk_ok(out);
}

lean_obj_res lean_ziglean_json_stream_init(void) {
  void* handle = NULL;
  uint32_t status = ziglean_json_stream_init(&handle);
  if (status == 2) {
    return mk_json_stream_error("zig json stream init alloc failed");
  }
  if (status != 0) {
    return mk_json_stream_error("zig json stream init failed");
  }
  return lean_io_result_mk_ok(lean_box_usize((size_t)handle));
}

lean_obj_res lean_ziglean_json_stream_feed(size_t handle, b_lean_obj_arg chunk) {
  size_t chunk_len = lean_sarray_size(chunk);
  const uint8_t* chunk_bytes = lean_sarray_cptr((lean_object*)chunk);
  uint32_t status = ziglean_json_stream_feed((void*)handle, chunk_bytes, (uint64_t)chunk_len);
  if (status == 2) {
    return mk_json_stream_error("zig json stream feed alloc failed");
  }
  if (status != 0) {
    return mk_json_stream_error("zig json stream feed failed");
  }
  return lean_io_result_mk_ok(lean_box(0));
}

lean_obj_res lean_ziglean_json_stream_end_input(size_t handle) {
  ziglean_json_stream_end_input((void*)handle);
  return lean_io_result_mk_ok(lean_box(0));
}

lean_obj_res lean_ziglean_json_stream_next(size_t handle) {
  ZigLeanJsonStreamResult result = {0, 0, 0, 0, 0};
  uint32_t status = ziglean_json_stream_next((void*)handle, &result);
  if (status != 0) {
    return mk_json_stream_error("zig json stream next failed");
  }
  return mk_stream_result(&result);
}

lean_obj_res lean_ziglean_json_stream_free(size_t handle) {
  ziglean_json_stream_free((void*)handle);
  return lean_io_result_mk_ok(lean_box(0));
}