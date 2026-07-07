#include <lean/lean.h>
#include <stdint.h>
#include <string.h>
#include "ziglean_crypto_aead.h"

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

static lean_obj_res mk_aead_error(const char* message) {
  lean_object* str = lean_mk_string(message);
  lean_object* err = lean_mk_io_user_error(str);
  return lean_io_result_mk_error(err);
}

static lean_obj_res copy_encrypt_output(ZigLeanAeadResult* result, const char* message) {
  if (result->status != 0) {
    ziglean_crypto_aead_free(result->out, result->out_len);
    return mk_aead_error(message);
  }
  lean_object* out = lean_alloc_sarray(1, (size_t)result->out_len, (size_t)result->out_len);
  if (result->out_len > 0) {
    memcpy(lean_sarray_cptr(out), result->out, (size_t)result->out_len);
  }
  ziglean_crypto_aead_free(result->out, result->out_len);
  return lean_io_result_mk_ok(out);
}

static lean_obj_res copy_decrypt_result(ZigLeanAeadResult* result) {
  size_t out_len = 16u + (result->status == 0 ? (size_t)result->out_len : 0u);
  lean_object* out = lean_alloc_sarray(1, out_len, out_len);
  uint8_t* dst = lean_sarray_cptr(out);
  write_u32(dst, result->status);
  write_u32(dst + 4, result->status);
  write_u64(dst + 8, result->error_offset);
  if (result->status == 0 && result->out_len > 0) {
    memcpy(dst + 16, result->out, (size_t)result->out_len);
  }
  ziglean_crypto_aead_free(result->out, result->out_len);
  return lean_io_result_mk_ok(out);
}

#define DEFINE_AEAD_ENCRYPT(lean_name, zig_name, err_msg) \
  lean_obj_res lean_name( \
    b_lean_obj_arg key, \
    b_lean_obj_arg nonce, \
    b_lean_obj_arg aad, \
    b_lean_obj_arg plaintext, \
    lean_obj_arg world \
  ) { \
    (void)world; \
    ZigLeanAeadResult result = {0, 0, 0, 0, 0}; \
    (void)zig_name( \
      lean_sarray_cptr((lean_object*)key), \
      lean_sarray_cptr((lean_object*)nonce), \
      lean_sarray_cptr((lean_object*)aad), \
      (uint64_t)lean_sarray_size(aad), \
      lean_sarray_cptr((lean_object*)plaintext), \
      (uint64_t)lean_sarray_size(plaintext), \
      &result \
    ); \
    return copy_encrypt_output(&result, err_msg); \
  }

#define DEFINE_AEAD_DECRYPT(lean_name, zig_name) \
  lean_obj_res lean_name( \
    b_lean_obj_arg key, \
    b_lean_obj_arg nonce, \
    b_lean_obj_arg aad, \
    b_lean_obj_arg ciphertext_and_tag, \
    lean_obj_arg world \
  ) { \
    (void)world; \
    ZigLeanAeadResult result = {0, 0, 0, 0, 0}; \
    (void)zig_name( \
      lean_sarray_cptr((lean_object*)key), \
      lean_sarray_cptr((lean_object*)nonce), \
      lean_sarray_cptr((lean_object*)aad), \
      (uint64_t)lean_sarray_size(aad), \
      lean_sarray_cptr((lean_object*)ciphertext_and_tag), \
      (uint64_t)lean_sarray_size(ciphertext_and_tag), \
      &result \
    ); \
    return copy_decrypt_result(&result); \
  }

DEFINE_AEAD_ENCRYPT(lean_ziglean_crypto_aes256gcm_encrypt, ziglean_crypto_aes256gcm_encrypt, "aes256gcm encrypt failed")
DEFINE_AEAD_DECRYPT(lean_ziglean_crypto_aes256gcm_decrypt, ziglean_crypto_aes256gcm_decrypt)
DEFINE_AEAD_ENCRYPT(lean_ziglean_crypto_aes256gcmsiv_encrypt, ziglean_crypto_aes256gcmsiv_encrypt, "aes256gcmsiv encrypt failed")
DEFINE_AEAD_DECRYPT(lean_ziglean_crypto_aes256gcmsiv_decrypt, ziglean_crypto_aes256gcmsiv_decrypt)
DEFINE_AEAD_ENCRYPT(lean_ziglean_crypto_aegis256_encrypt, ziglean_crypto_aegis256_encrypt, "aegis256 encrypt failed")
DEFINE_AEAD_DECRYPT(lean_ziglean_crypto_aegis256_decrypt, ziglean_crypto_aegis256_decrypt)
DEFINE_AEAD_ENCRYPT(lean_ziglean_crypto_chacha20poly1305_encrypt, ziglean_crypto_chacha20poly1305_encrypt, "chacha20poly1305 encrypt failed")
DEFINE_AEAD_DECRYPT(lean_ziglean_crypto_chacha20poly1305_decrypt, ziglean_crypto_chacha20poly1305_decrypt)