#include <lean/lean.h>
#include <stdint.h>
#include "ziglean_crypto_hash.h"

static lean_obj_res mk_crypto_error(const char* message) {
  lean_object* str = lean_mk_string(message);
  lean_object* err = lean_mk_io_user_error(str);
  return lean_io_result_mk_error(err);
}

static lean_obj_res mk_digest_result(void) {
  return lean_alloc_sarray(1, ZIGLEAN_CRYPTO_SHA256_LEN, ZIGLEAN_CRYPTO_SHA256_LEN);
}

lean_obj_res lean_ziglean_crypto_sha256(b_lean_obj_arg input, lean_obj_arg world) {
  (void)world;
  size_t input_len = lean_sarray_size(input);
  const uint8_t* input_bytes = lean_sarray_cptr((lean_object*)input);
  lean_object* out = mk_digest_result();
  uint32_t status = ziglean_crypto_sha256(input_bytes, (uint64_t)input_len, lean_sarray_cptr(out));
  if (status != 0) {
    lean_dec(out);
    return mk_crypto_error("zig sha256 failed");
  }
  return lean_io_result_mk_ok(out);
}

lean_obj_res lean_ziglean_crypto_blake3(b_lean_obj_arg input, lean_obj_arg world) {
  (void)world;
  size_t input_len = lean_sarray_size(input);
  const uint8_t* input_bytes = lean_sarray_cptr((lean_object*)input);
  lean_object* out = mk_digest_result();
  uint32_t status = ziglean_crypto_blake3(input_bytes, (uint64_t)input_len, lean_sarray_cptr(out));
  if (status != 0) {
    lean_dec(out);
    return mk_crypto_error("zig blake3 failed");
  }
  return lean_io_result_mk_ok(out);
}

lean_obj_res lean_ziglean_crypto_hmac_sha256(
  b_lean_obj_arg key,
  b_lean_obj_arg message,
  lean_obj_arg world
) {
  (void)world;
  size_t key_len = lean_sarray_size(key);
  size_t message_len = lean_sarray_size(message);
  const uint8_t* key_bytes = lean_sarray_cptr((lean_object*)key);
  const uint8_t* message_bytes = lean_sarray_cptr((lean_object*)message);
  lean_object* out = mk_digest_result();
  uint32_t status = ziglean_crypto_hmac_sha256(
    key_bytes,
    (uint64_t)key_len,
    message_bytes,
    (uint64_t)message_len,
    lean_sarray_cptr(out)
  );
  if (status != 0) {
    lean_dec(out);
    return mk_crypto_error("zig hmac sha256 failed");
  }
  return lean_io_result_mk_ok(out);
}
