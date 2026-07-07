#include <lean/lean.h>
#include <stdint.h>
#include <string.h>
#include "ziglean_crypto_dh.h"

static lean_obj_res mk_dh_error(const char* message) {
  lean_object* str = lean_mk_string(message);
  lean_object* err = lean_io_result_mk_error(lean_mk_io_user_error(str));
  return err;
}

lean_obj_res lean_ziglean_crypto_x25519_keypair(
  b_lean_obj_arg seed,
  lean_obj_arg world
) {
  (void)world;
  if (lean_sarray_size(seed) != ZIGLEAN_X25519_SEED_LEN) {
    return mk_dh_error("x25519 seed must be 32 bytes");
  }
  lean_object* out = lean_alloc_sarray(1, ZIGLEAN_X25519_KEYPAIR_LEN, ZIGLEAN_X25519_KEYPAIR_LEN);
  uint32_t status = ziglean_crypto_x25519_keypair(
    lean_sarray_cptr((lean_object*)seed),
    lean_sarray_cptr(out)
  );
  if (status != 0) {
    lean_dec(out);
    return mk_dh_error("x25519 keypair generation failed");
  }
  return lean_io_result_mk_ok(out);
}

lean_obj_res lean_ziglean_crypto_x25519_shared_secret(
  b_lean_obj_arg secret_key,
  b_lean_obj_arg public_key,
  lean_obj_arg world
) {
  (void)world;
  if (lean_sarray_size(secret_key) != ZIGLEAN_X25519_SECRET_KEY_LEN) {
    return mk_dh_error("x25519 secret key must be 32 bytes");
  }
  if (lean_sarray_size(public_key) != ZIGLEAN_X25519_PUBLIC_KEY_LEN) {
    return mk_dh_error("x25519 public key must be 32 bytes");
  }
  lean_object* out = lean_alloc_sarray(1, ZIGLEAN_X25519_SHARED_SECRET_LEN, ZIGLEAN_X25519_SHARED_SECRET_LEN);
  uint32_t status = ziglean_crypto_x25519_shared_secret(
    lean_sarray_cptr((lean_object*)secret_key),
    lean_sarray_cptr((lean_object*)public_key),
    lean_sarray_cptr(out)
  );
  if (status != 0) {
    lean_dec(out);
    return mk_dh_error("x25519 shared secret computation failed");
  }
  return lean_io_result_mk_ok(out);
}
