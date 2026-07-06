#include <lean/lean.h>
#include <stdint.h>
#include <string.h>
#include "ziglean_crypto_kdf.h"

static lean_obj_res mk_kdf_error(const char* message) {
  lean_object* str = lean_mk_string(message);
  lean_object* err = lean_mk_io_user_error(str);
  return lean_io_result_mk_error(err);
}

static lean_obj_res copy_kdf_output(uint8_t* bytes, uint64_t len) {
  lean_object* out = lean_alloc_sarray(1, (size_t)len, (size_t)len);
  if (len > 0) {
    memcpy(lean_sarray_cptr(out), bytes, (size_t)len);
  }
  ziglean_crypto_kdf_free(bytes, len);
  return lean_io_result_mk_ok(out);
}

lean_obj_res lean_ziglean_crypto_hkdf_sha256(
  b_lean_obj_arg salt,
  b_lean_obj_arg ikm,
  b_lean_obj_arg info,
  uint64_t out_len,
  lean_obj_arg world
) {
  (void)world;
  uint8_t* out = 0;
  uint32_t status = ziglean_crypto_hkdf_sha256(
    lean_sarray_cptr((lean_object*)salt),
    (uint64_t)lean_sarray_size(salt),
    lean_sarray_cptr((lean_object*)ikm),
    (uint64_t)lean_sarray_size(ikm),
    lean_sarray_cptr((lean_object*)info),
    (uint64_t)lean_sarray_size(info),
    out_len,
    &out
  );
  if (status != 0) {
    ziglean_crypto_kdf_free(out, out_len);
    return mk_kdf_error("hkdf sha256 failed");
  }
  return copy_kdf_output(out, out_len);
}

lean_obj_res lean_ziglean_crypto_pbkdf2_sha256(
  b_lean_obj_arg password,
  b_lean_obj_arg salt,
  uint32_t rounds,
  uint64_t out_len,
  lean_obj_arg world
) {
  (void)world;
  uint8_t* out = 0;
  uint32_t status = ziglean_crypto_pbkdf2_sha256(
    lean_sarray_cptr((lean_object*)password),
    (uint64_t)lean_sarray_size(password),
    lean_sarray_cptr((lean_object*)salt),
    (uint64_t)lean_sarray_size(salt),
    rounds,
    out_len,
    &out
  );
  if (status != 0) {
    ziglean_crypto_kdf_free(out, out_len);
    return mk_kdf_error("pbkdf2 sha256 failed");
  }
  return copy_kdf_output(out, out_len);
}

lean_obj_res lean_ziglean_crypto_scrypt(
  b_lean_obj_arg password,
  b_lean_obj_arg salt,
  uint32_t ln,
  uint32_t r,
  uint32_t p,
  uint64_t out_len,
  lean_obj_arg world
) {
  (void)world;
  uint8_t* out = 0;
  uint32_t status = ziglean_crypto_scrypt(
    lean_sarray_cptr((lean_object*)password),
    (uint64_t)lean_sarray_size(password),
    lean_sarray_cptr((lean_object*)salt),
    (uint64_t)lean_sarray_size(salt),
    ln,
    r,
    p,
    out_len,
    &out
  );
  if (status != 0) {
    ziglean_crypto_kdf_free(out, out_len);
    return mk_kdf_error("scrypt failed");
  }
  return copy_kdf_output(out, out_len);
}

lean_obj_res lean_ziglean_crypto_argon2id(
  b_lean_obj_arg password,
  b_lean_obj_arg salt,
  uint32_t t,
  uint32_t m_kib,
  uint32_t p,
  uint64_t out_len,
  lean_obj_arg world
) {
  (void)world;
  uint8_t* out = 0;
  uint32_t status = ziglean_crypto_argon2id(
    lean_sarray_cptr((lean_object*)password),
    (uint64_t)lean_sarray_size(password),
    lean_sarray_cptr((lean_object*)salt),
    (uint64_t)lean_sarray_size(salt),
    t,
    m_kib,
    p,
    out_len,
    &out
  );
  if (status != 0) {
    ziglean_crypto_kdf_free(out, out_len);
    return mk_kdf_error("argon2id failed");
  }
  return copy_kdf_output(out, out_len);
}