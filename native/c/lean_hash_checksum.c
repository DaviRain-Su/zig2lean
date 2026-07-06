#include <lean/lean.h>
#include <stdint.h>
#include "ziglean_hash_checksum.h"

static lean_obj_res mk_checksum_error(const char* message) {
  lean_object* str = lean_mk_string(message);
  lean_object* err = lean_mk_io_user_error(str);
  return lean_io_result_mk_error(err);
}

lean_obj_res lean_ziglean_hash_crc32(b_lean_obj_arg input, lean_obj_arg world) {
  (void)world;
  uint32_t crc = 0;
  uint32_t status = ziglean_hash_crc32(
    lean_sarray_cptr((lean_object*)input),
    (uint64_t)lean_sarray_size(input),
    &crc
  );
  if (status != 0) {
    return mk_checksum_error("crc32 failed");
  }
  return lean_io_result_mk_ok(lean_box_uint32(crc));
}

lean_obj_res lean_ziglean_hash_xxhash64(uint64_t seed, b_lean_obj_arg input, lean_obj_arg world) {
  (void)world;
  uint64_t hash = 0;
  uint32_t status = ziglean_hash_xxhash64(
    seed,
    lean_sarray_cptr((lean_object*)input),
    (uint64_t)lean_sarray_size(input),
    &hash
  );
  if (status != 0) {
    return mk_checksum_error("xxhash64 failed");
  }
  return lean_io_result_mk_ok(lean_box_uint64(hash));
}