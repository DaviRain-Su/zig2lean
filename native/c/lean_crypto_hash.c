#include <lean/lean.h>
#include <stdint.h>
#include "ziglean_crypto_hash.h"

static lean_obj_res mk_crypto_error(const char* message) {
  lean_object* str = lean_mk_string(message);
  lean_object* err = lean_mk_io_user_error(str);
  return lean_io_result_mk_error(err);
}

static lean_obj_res mk_digest_result(size_t len) {
  return lean_alloc_sarray(1, len, len);
}

lean_obj_res lean_ziglean_crypto_sha224(b_lean_obj_arg input, lean_obj_arg world) {
  (void)world;
  size_t input_len = lean_sarray_size(input);
  const uint8_t* input_bytes = lean_sarray_cptr((lean_object*)input);
  lean_object* out = mk_digest_result(ZIGLEAN_CRYPTO_SHA224_LEN);
  uint32_t status = ziglean_crypto_sha224(input_bytes, (uint64_t)input_len, lean_sarray_cptr(out));
  if (status != 0) {
    lean_dec(out);
    return mk_crypto_error("zig sha224 failed");
  }
  return lean_io_result_mk_ok(out);
}

lean_obj_res lean_ziglean_crypto_sha256(b_lean_obj_arg input, lean_obj_arg world) {
  (void)world;
  size_t input_len = lean_sarray_size(input);
  const uint8_t* input_bytes = lean_sarray_cptr((lean_object*)input);
  lean_object* out = mk_digest_result(ZIGLEAN_CRYPTO_SHA256_LEN);
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
  lean_object* out = mk_digest_result(ZIGLEAN_CRYPTO_BLAKE3_LEN);
  uint32_t status = ziglean_crypto_blake3(input_bytes, (uint64_t)input_len, lean_sarray_cptr(out));
  if (status != 0) {
    lean_dec(out);
    return mk_crypto_error("zig blake3 failed");
  }
  return lean_io_result_mk_ok(out);
}

lean_obj_res lean_ziglean_crypto_blake2b256(b_lean_obj_arg input, lean_obj_arg world) {
  (void)world;
  size_t input_len = lean_sarray_size(input);
  const uint8_t* input_bytes = lean_sarray_cptr((lean_object*)input);
  lean_object* out = mk_digest_result(ZIGLEAN_CRYPTO_BLAKE2B256_LEN);
  uint32_t status = ziglean_crypto_blake2b256(input_bytes, (uint64_t)input_len, lean_sarray_cptr(out));
  if (status != 0) {
    lean_dec(out);
    return mk_crypto_error("zig blake2b256 failed");
  }
  return lean_io_result_mk_ok(out);
}

lean_obj_res lean_ziglean_crypto_blake2s256(b_lean_obj_arg input, lean_obj_arg world) {
  (void)world;
  size_t input_len = lean_sarray_size(input);
  const uint8_t* input_bytes = lean_sarray_cptr((lean_object*)input);
  lean_object* out = mk_digest_result(ZIGLEAN_CRYPTO_BLAKE2S256_LEN);
  uint32_t status = ziglean_crypto_blake2s256(input_bytes, (uint64_t)input_len, lean_sarray_cptr(out));
  if (status != 0) {
    lean_dec(out);
    return mk_crypto_error("zig blake2s256 failed");
  }
  return lean_io_result_mk_ok(out);
}

lean_obj_res lean_ziglean_crypto_blake2b512(b_lean_obj_arg input, lean_obj_arg world) {
  (void)world;
  size_t input_len = lean_sarray_size(input);
  const uint8_t* input_bytes = lean_sarray_cptr((lean_object*)input);
  lean_object* out = mk_digest_result(ZIGLEAN_CRYPTO_BLAKE2B512_LEN);
  uint32_t status = ziglean_crypto_blake2b512(input_bytes, (uint64_t)input_len, lean_sarray_cptr(out));
  if (status != 0) {
    lean_dec(out);
    return mk_crypto_error("zig blake2b512 failed");
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
  lean_object* out = mk_digest_result(ZIGLEAN_CRYPTO_HMAC_SHA256_LEN);
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

lean_obj_res lean_ziglean_crypto_hmac_sha512(
  b_lean_obj_arg key,
  b_lean_obj_arg message,
  lean_obj_arg world
) {
  (void)world;
  size_t key_len = lean_sarray_size(key);
  size_t message_len = lean_sarray_size(message);
  const uint8_t* key_bytes = lean_sarray_cptr((lean_object*)key);
  const uint8_t* message_bytes = lean_sarray_cptr((lean_object*)message);
  lean_object* out = mk_digest_result(ZIGLEAN_CRYPTO_HMAC_SHA512_LEN);
  uint32_t status = ziglean_crypto_hmac_sha512(
    key_bytes,
    (uint64_t)key_len,
    message_bytes,
    (uint64_t)message_len,
    lean_sarray_cptr(out)
  );
  if (status != 0) {
    lean_dec(out);
    return mk_crypto_error("zig hmac sha512 failed");
  }
  return lean_io_result_mk_ok(out);
}

lean_obj_res lean_ziglean_crypto_sha384(b_lean_obj_arg input, lean_obj_arg world) {
  (void)world;
  size_t input_len = lean_sarray_size(input);
  const uint8_t* input_bytes = lean_sarray_cptr((lean_object*)input);
  lean_object* out = mk_digest_result(ZIGLEAN_CRYPTO_SHA384_LEN);
  uint32_t status = ziglean_crypto_sha384(input_bytes, (uint64_t)input_len, lean_sarray_cptr(out));
  if (status != 0) {
    lean_dec(out);
    return mk_crypto_error("zig sha384 failed");
  }
  return lean_io_result_mk_ok(out);
}

lean_obj_res lean_ziglean_crypto_sha512(b_lean_obj_arg input, lean_obj_arg world) {
  (void)world;
  size_t input_len = lean_sarray_size(input);
  const uint8_t* input_bytes = lean_sarray_cptr((lean_object*)input);
  lean_object* out = mk_digest_result(ZIGLEAN_CRYPTO_SHA512_LEN);
  uint32_t status = ziglean_crypto_sha512(input_bytes, (uint64_t)input_len, lean_sarray_cptr(out));
  if (status != 0) {
    lean_dec(out);
    return mk_crypto_error("zig sha512 failed");
  }
  return lean_io_result_mk_ok(out);
}

lean_obj_res lean_ziglean_crypto_sha3_224(b_lean_obj_arg input, lean_obj_arg world) {
  (void)world;
  size_t input_len = lean_sarray_size(input);
  const uint8_t* input_bytes = lean_sarray_cptr((lean_object*)input);
  lean_object* out = mk_digest_result(ZIGLEAN_CRYPTO_SHA3_224_LEN);
  uint32_t status = ziglean_crypto_sha3_224(input_bytes, (uint64_t)input_len, lean_sarray_cptr(out));
  if (status != 0) {
    lean_dec(out);
    return mk_crypto_error("zig sha3_224 failed");
  }
  return lean_io_result_mk_ok(out);
}

lean_obj_res lean_ziglean_crypto_sha3_256(b_lean_obj_arg input, lean_obj_arg world) {
  (void)world;
  size_t input_len = lean_sarray_size(input);
  const uint8_t* input_bytes = lean_sarray_cptr((lean_object*)input);
  lean_object* out = mk_digest_result(ZIGLEAN_CRYPTO_SHA3_256_LEN);
  uint32_t status = ziglean_crypto_sha3_256(input_bytes, (uint64_t)input_len, lean_sarray_cptr(out));
  if (status != 0) {
    lean_dec(out);
    return mk_crypto_error("zig sha3_256 failed");
  }
  return lean_io_result_mk_ok(out);
}

lean_obj_res lean_ziglean_crypto_sha3_384(b_lean_obj_arg input, lean_obj_arg world) {
  (void)world;
  size_t input_len = lean_sarray_size(input);
  const uint8_t* input_bytes = lean_sarray_cptr((lean_object*)input);
  lean_object* out = mk_digest_result(ZIGLEAN_CRYPTO_SHA3_384_LEN);
  uint32_t status = ziglean_crypto_sha3_384(input_bytes, (uint64_t)input_len, lean_sarray_cptr(out));
  if (status != 0) {
    lean_dec(out);
    return mk_crypto_error("zig sha3_384 failed");
  }
  return lean_io_result_mk_ok(out);
}

lean_obj_res lean_ziglean_crypto_sha3_512(b_lean_obj_arg input, lean_obj_arg world) {
  (void)world;
  size_t input_len = lean_sarray_size(input);
  const uint8_t* input_bytes = lean_sarray_cptr((lean_object*)input);
  lean_object* out = mk_digest_result(ZIGLEAN_CRYPTO_SHA3_512_LEN);
  uint32_t status = ziglean_crypto_sha3_512(input_bytes, (uint64_t)input_len, lean_sarray_cptr(out));
  if (status != 0) {
    lean_dec(out);
    return mk_crypto_error("zig sha3_512 failed");
  }
  return lean_io_result_mk_ok(out);
}

lean_obj_res lean_ziglean_crypto_keccak256(b_lean_obj_arg input, lean_obj_arg world) {
  (void)world;
  size_t input_len = lean_sarray_size(input);
  const uint8_t* input_bytes = lean_sarray_cptr((lean_object*)input);
  lean_object* out = mk_digest_result(ZIGLEAN_CRYPTO_KECCAK256_LEN);
  uint32_t status = ziglean_crypto_keccak256(input_bytes, (uint64_t)input_len, lean_sarray_cptr(out));
  if (status != 0) {
    lean_dec(out);
    return mk_crypto_error("zig keccak256 failed");
  }
  return lean_io_result_mk_ok(out);
}
