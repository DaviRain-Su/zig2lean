#include <lean/lean.h>
#include <stdint.h>
#include "ziglean_crypto_hash_stream.h"

static lean_obj_res mk_stream_error(const char* message) {
  lean_object* str = lean_mk_string(message);
  lean_object* err = lean_mk_io_user_error(str);
  return lean_io_result_mk_error(err);
}

static lean_obj_res mk_digest_result(size_t len) {
  return lean_alloc_sarray(1, len, len);
}

lean_obj_res lean_ziglean_crypto_hash_stream_init(uint32_t algo) {
  void* handle = NULL;
  uint32_t status = ziglean_crypto_hash_stream_init(algo, &handle);
  if (status == 2) {
    return mk_stream_error("zig hash stream init alloc failed");
  }
  if (status != 0) {
    return mk_stream_error("zig hash stream init failed");
  }
  return lean_io_result_mk_ok(lean_box_usize((size_t)handle));
}

lean_obj_res lean_ziglean_crypto_hash_stream_update(size_t handle, b_lean_obj_arg input) {
  size_t input_len = lean_sarray_size(input);
  const uint8_t* input_bytes = lean_sarray_cptr((lean_object*)input);
  uint32_t status = ziglean_crypto_hash_stream_update(
    (void*)handle,
    input_bytes,
    (uint64_t)input_len
  );
  return lean_io_result_mk_ok(lean_box_uint32(status));
}

lean_obj_res lean_ziglean_crypto_hash_stream_final(size_t handle, uint32_t digest_len) {
  lean_object* out = mk_digest_result((size_t)digest_len);
  uint32_t status = ziglean_crypto_hash_stream_final(
    (void*)handle,
    lean_sarray_cptr(out),
    (uint64_t)digest_len
  );
  if (status == 3) {
    lean_dec(out);
    return mk_stream_error("zig hash stream already finalized");
  }
  if (status != 0) {
    lean_dec(out);
    return mk_stream_error("zig hash stream final failed");
  }
  return lean_io_result_mk_ok(out);
}

lean_obj_res lean_ziglean_crypto_hash_stream_free(size_t handle) {
  ziglean_crypto_hash_stream_free((void*)handle);
  return lean_io_result_mk_ok(lean_box(0));
}