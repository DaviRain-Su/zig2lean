#include <lean/lean.h>
#include <stdint.h>
#include "ziglean_crypto_sign.h"

static lean_obj_res mk_sign_error(const char* message) {
  lean_object* str = lean_mk_string(message);
  lean_object* err = lean_mk_io_user_error(str);
  return lean_io_result_mk_error(err);
}

lean_obj_res lean_ziglean_crypto_ed25519_sign(
  b_lean_obj_arg seed,
  b_lean_obj_arg message,
  lean_obj_arg world
) {
  (void)world;
  if (lean_sarray_size(seed) != ZIGLEAN_ED25519_SEED_LEN) {
    return mk_sign_error("ed25519 seed must be 32 bytes");
  }
  lean_object* out = lean_alloc_sarray(1, ZIGLEAN_ED25519_SIGNATURE_LEN, ZIGLEAN_ED25519_SIGNATURE_LEN);
  uint32_t status = ziglean_crypto_ed25519_sign(
    lean_sarray_cptr((lean_object*)seed),
    lean_sarray_cptr((lean_object*)message),
    (uint64_t)lean_sarray_size(message),
    lean_sarray_cptr(out)
  );
  if (status != 0) {
    lean_dec(out);
    return mk_sign_error("ed25519 sign failed");
  }
  return lean_io_result_mk_ok(out);
}

lean_obj_res lean_ziglean_crypto_ed25519_verify(
  b_lean_obj_arg public_key,
  b_lean_obj_arg message,
  b_lean_obj_arg signature,
  lean_obj_arg world
) {
  (void)world;
  uint32_t valid = 0;
  uint32_t status = ziglean_crypto_ed25519_verify(
    lean_sarray_cptr((lean_object*)public_key),
    lean_sarray_cptr((lean_object*)message),
    (uint64_t)lean_sarray_size(message),
    lean_sarray_cptr((lean_object*)signature),
    &valid
  );
  if (status != 0) {
    return mk_sign_error("ed25519 verify failed");
  }
  return lean_io_result_mk_ok(lean_box(valid != 0));
}

lean_obj_res lean_ziglean_crypto_secp256k1_sign(
  b_lean_obj_arg secret_key,
  b_lean_obj_arg message,
  lean_obj_arg world
) {
  (void)world;
  if (lean_sarray_size(secret_key) != ZIGLEAN_SECP256K1_SECRET_KEY_LEN) {
    return mk_sign_error("secp256k1 secret key must be 32 bytes");
  }
  lean_object* out = lean_alloc_sarray(1, ZIGLEAN_SECP256K1_SIGNATURE_LEN, ZIGLEAN_SECP256K1_SIGNATURE_LEN);
  uint32_t status = ziglean_crypto_secp256k1_sign(
    lean_sarray_cptr((lean_object*)secret_key),
    lean_sarray_cptr((lean_object*)message),
    (uint64_t)lean_sarray_size(message),
    lean_sarray_cptr(out)
  );
  if (status != 0) {
    lean_dec(out);
    return mk_sign_error("secp256k1 sign failed");
  }
  return lean_io_result_mk_ok(out);
}

lean_obj_res lean_ziglean_crypto_secp256k1_verify(
  b_lean_obj_arg public_key,
  b_lean_obj_arg message,
  b_lean_obj_arg signature,
  lean_obj_arg world
) {
  (void)world;
  uint32_t valid = 0;
  uint32_t status = ziglean_crypto_secp256k1_verify(
    lean_sarray_cptr((lean_object*)public_key),
    (uint64_t)lean_sarray_size(public_key),
    lean_sarray_cptr((lean_object*)message),
    (uint64_t)lean_sarray_size(message),
    lean_sarray_cptr((lean_object*)signature),
    &valid
  );
  if (status != 0) {
    return mk_sign_error("secp256k1 verify failed");
  }
  return lean_io_result_mk_ok(lean_box(valid != 0));
}