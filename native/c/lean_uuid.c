#include <lean/lean.h>
#include <stdint.h>
#include <string.h>
#include "ziglean_uuid.h"

static lean_obj_res mk_uuid_error(const char* message) {
  lean_object* str = lean_mk_string(message);
  lean_object* err = lean_mk_io_user_error(str);
  return lean_io_result_mk_error(err);
}

lean_obj_res lean_ziglean_uuid_v4(lean_obj_arg world) {
  (void)world;
  ZigLeanUuidResult result = {0, 0, 0, 0};
  uint32_t status = ziglean_uuid_v4(&result);
  if (status != 0) {
    // Zig guarantees result.out is null on error; nothing to free.
    return mk_uuid_error("uuid v4 generation failed");
  }
  lean_object* out = lean_mk_string_from_bytes((const char*)result.out, (size_t)result.out_len);
  ziglean_uuid_free(result.out, result.out_len);
  return lean_io_result_mk_ok(out);
}
