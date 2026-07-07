#include <lean/lean.h>
#include <stdint.h>
#include <string.h>
#include "ziglean_random.h"

static lean_obj_res mk_random_error(const char* message) {
  lean_object* str = lean_mk_string(message);
  lean_object* err = lean_mk_io_user_error(str);
  return lean_io_result_mk_error(err);
}

lean_obj_res lean_ziglean_random_bytes(uint64_t len, lean_obj_arg world) {
  (void)world;
  ZigLeanRandomResult result = {0, 0, 0, 0};
  uint32_t status = ziglean_random_bytes(len, &result);
  if (status != 0) {
    ziglean_random_free(result.out, result.out_len);
    return mk_random_error("random bytes generation failed");
  }
  lean_object* out = lean_alloc_sarray(1, (size_t)result.out_len, (size_t)result.out_len);
  if (result.out_len > 0) {
    memcpy(lean_sarray_cptr(out), result.out, (size_t)result.out_len);
  }
  ziglean_random_free(result.out, result.out_len);
  return lean_io_result_mk_ok(out);
}
