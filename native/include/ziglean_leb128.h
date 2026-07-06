#ifndef ZIGLEAN_LEB128_H
#define ZIGLEAN_LEB128_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
  uint32_t status;
  uint32_t reserved;
  uint64_t out_len;
  uint64_t value;
  uint8_t* out;
} ZigLeanLeb128Result;

uint32_t ziglean_leb128_encode_u64(uint64_t value, ZigLeanLeb128Result* out_result);
uint32_t ziglean_leb128_decode_u64(const uint8_t* input, uint64_t input_len, ZigLeanLeb128Result* out_result);
uint32_t ziglean_leb128_encode_i64(int64_t value, ZigLeanLeb128Result* out_result);
uint32_t ziglean_leb128_decode_i64(const uint8_t* input, uint64_t input_len, ZigLeanLeb128Result* out_result);
void ziglean_leb128_free(uint8_t* ptr, uint64_t len);

#ifdef __cplusplus
}
#endif

#endif