#include <lean/lean.h>
#include <stdint.h>
#include <string.h>
#include "ziglean_crypto_stream_cipher.h"

static lean_obj_res mk_stream_cipher_error(const char* message) {
  lean_object* str = lean_mk_string(message);
  lean_object* err = lean_mk_io_user_error(str);
  return lean_io_result_mk_error(err);
}

static lean_obj_res run_stream_cipher(
    uint32_t (*fn)(
      const uint8_t*, const uint8_t*, uint32_t, const uint8_t*, uint64_t,
      ZigLeanStreamCipherResult*),
    b_lean_obj_arg key,
    b_lean_obj_arg nonce,
    uint32_t counter,
    b_lean_obj_arg input,
    lean_obj_arg world
) {
  (void)world;
  if (lean_sarray_size(key) != 32) {
    return mk_stream_cipher_error("chacha20 key must be 32 bytes");
  }
  const uint8_t* key_bytes = lean_sarray_cptr((lean_object*)key);
  const uint8_t* nonce_bytes = lean_sarray_cptr((lean_object*)nonce);
  const uint8_t* input_bytes = lean_sarray_cptr((lean_object*)input);
  uint64_t input_len = lean_sarray_size(input);
  ZigLeanStreamCipherResult result = {0, 0, 0, 0};
  uint32_t status = fn(
    key_bytes, nonce_bytes, counter, input_bytes, input_len, &result);
  if (status != 0) {
    return mk_stream_cipher_error("chacha20 xor failed");
  }
  lean_object* out = lean_alloc_sarray(1, (size_t)result.out_len, (size_t)result.out_len);
  if (result.out_len > 0) {
    memcpy(lean_sarray_cptr(out), result.out, (size_t)result.out_len);
  }
  ziglean_crypto_stream_cipher_free(result.out, result.out_len);
  return lean_io_result_mk_ok(out);
}

lean_obj_res lean_ziglean_crypto_chacha20_xor(
  b_lean_obj_arg key,
  b_lean_obj_arg nonce,
  uint32_t counter,
  b_lean_obj_arg input,
  lean_obj_arg world
) {
  return run_stream_cipher(
    ziglean_crypto_chacha20_xor, key, nonce, counter, input, world);
}

lean_obj_res lean_ziglean_crypto_xchacha20_xor(
  b_lean_obj_arg key,
  b_lean_obj_arg nonce,
  uint32_t counter,
  b_lean_obj_arg input,
  lean_obj_arg world
) {
  return run_stream_cipher(
    ziglean_crypto_xchacha20_xor, key, nonce, counter, input, world);
}

lean_obj_res lean_ziglean_crypto_chacha20_legacy_xor(
  b_lean_obj_arg key,
  b_lean_obj_arg nonce,
  uint64_t counter,
  b_lean_obj_arg input,
  lean_obj_arg world
) {
  (void)world;
  if (lean_sarray_size(key) != 32) {
    return mk_stream_cipher_error("chacha20 legacy key must be 32 bytes");
  }
  if (lean_sarray_size(nonce) != 8) {
    return mk_stream_cipher_error("chacha20 legacy nonce must be 8 bytes");
  }
  const uint8_t* key_bytes = lean_sarray_cptr((lean_object*)key);
  const uint8_t* nonce_bytes = lean_sarray_cptr((lean_object*)nonce);
  const uint8_t* input_bytes = lean_sarray_cptr((lean_object*)input);
  uint64_t input_len = lean_sarray_size(input);
  ZigLeanStreamCipherResult result = {0, 0, 0, 0};
  uint32_t status = ziglean_crypto_chacha20_legacy_xor(
    key_bytes, nonce_bytes, counter, input_bytes, input_len, &result);
  if (status != 0) {
    return mk_stream_cipher_error("chacha20 legacy xor failed");
  }
  lean_object* out = lean_alloc_sarray(1, (size_t)result.out_len, (size_t)result.out_len);
  if (result.out_len > 0) {
    memcpy(lean_sarray_cptr(out), result.out, (size_t)result.out_len);
  }
  ziglean_crypto_stream_cipher_free(result.out, result.out_len);
  return lean_io_result_mk_ok(out);
}
