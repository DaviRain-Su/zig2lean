#include <lean/lean.h>
#include <stdint.h>
#include <string.h>
#include "ziglean_json.h"

lean_obj_res lean_ziglean_json_validate_raw(b_lean_obj_arg input, lean_obj_arg world) {
  size_t len = lean_sarray_size(input);
  const uint8_t* bytes = lean_sarray_cptr((lean_object*)input);
  uint32_t status = ziglean_json_validate(bytes, (uint64_t)len);
  lean_object* boxed = lean_box_uint32(status);
  return lean_io_result_mk_ok(boxed);
}

lean_obj_res lean_ziglean_json_parse_tokens_raw(b_lean_obj_arg input, lean_obj_arg world) {
  (void)world;
  (void)input;
  lean_object* out = lean_alloc_sarray(1, 16, 16);
  uint8_t* dst = lean_sarray_cptr(out);
  memset(dst, 0, 16);
  return lean_io_result_mk_ok(out);
}
