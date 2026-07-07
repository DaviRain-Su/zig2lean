#include <lean/lean.h>
#include <stdint.h>
#include <string.h>
#include "ziglean_crypto_aes.h"

static lean_obj_res mk_aes_error(const char* message) {
  lean_object* str = lean_mk_string(message);
  lean_object* err = lean_mk_io_user_error(str);
  return lean_io_result_mk_error(err);
}

static lean_obj_res run_cipher(
    uint32_t (*fn)(
      const uint8_t*, const uint8_t*, const uint8_t*, uint64_t,
      ZigLeanCipherResult*),
    b_lean_obj_arg key,
    b_lean_obj_arg iv,
    b_lean_obj_arg input,
    lean_obj_arg world
) {
  (void)world;
  if (lean_sarray_size(key) != 32) {
    return mk_aes_error("aes256 key must be 32 bytes");
  }
  const uint8_t* key_bytes = lean_sarray_cptr((lean_object*)key);
  const uint8_t* iv_bytes = lean_sarray_cptr((lean_object*)iv);
  const uint8_t* input_bytes = lean_sarray_cptr((lean_object*)input);
  uint64_t input_len = lean_sarray_size(input);
  ZigLeanCipherResult result = {0, 0, 0, 0};
  uint32_t status = fn(key_bytes, iv_bytes, input_bytes, input_len, &result);
  if (status != 0) {
    return mk_aes_error("aes256 cipher operation failed");
  }
  lean_object* out = lean_alloc_sarray(1, (size_t)result.out_len, (size_t)result.out_len);
  if (result.out_len > 0) {
    memcpy(lean_sarray_cptr(out), result.out, (size_t)result.out_len);
  }
  ziglean_crypto_cipher_free(result.out, result.out_len);
  return lean_io_result_mk_ok(out);
}

lean_obj_res lean_ziglean_crypto_aes256_cbc_encrypt(
  b_lean_obj_arg key,
  b_lean_obj_arg iv,
  b_lean_obj_arg input,
  lean_obj_arg world
) {
  return run_cipher(ziglean_crypto_aes256_cbc_encrypt, key, iv, input, world);
}

lean_obj_res lean_ziglean_crypto_aes256_cbc_decrypt(
  b_lean_obj_arg key,
  b_lean_obj_arg iv,
  b_lean_obj_arg input,
  lean_obj_arg world
) {
  return run_cipher(ziglean_crypto_aes256_cbc_decrypt, key, iv, input, world);
}

lean_obj_res lean_ziglean_crypto_aes256_ctr(
  b_lean_obj_arg key,
  b_lean_obj_arg iv,
  b_lean_obj_arg input,
  lean_obj_arg world
) {
  (void)world;
  if (lean_sarray_size(key) != 32) {
    return mk_aes_error("aes256 key must be 32 bytes");
  }
  const uint8_t* key_bytes = lean_sarray_cptr((lean_object*)key);
  const uint8_t* iv_bytes = lean_sarray_cptr((lean_object*)iv);
  const uint8_t* input_bytes = lean_sarray_cptr((lean_object*)input);
  uint64_t input_len = lean_sarray_size(input);
  ZigLeanCipherResult result = {0, 0, 0, 0};
  uint32_t status = ziglean_crypto_aes256_ctr(
    key_bytes, iv_bytes, lean_sarray_size((lean_object*)iv),
    input_bytes, input_len, &result);
  if (status != 0) {
    return mk_aes_error("aes256 ctr failed");
  }
  lean_object* out = lean_alloc_sarray(1, (size_t)result.out_len, (size_t)result.out_len);
  if (result.out_len > 0) {
    memcpy(lean_sarray_cptr(out), result.out, (size_t)result.out_len);
  }
  ziglean_crypto_cipher_free(result.out, result.out_len);
  return lean_io_result_mk_ok(out);
}
