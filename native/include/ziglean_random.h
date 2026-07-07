#ifndef ZIGLEAN_RANDOM_H
#define ZIGLEAN_RANDOM_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
  uint32_t status;
  uint32_t reserved;
  uint64_t out_len;
  uint8_t* out;
} ZigLeanRandomResult;

uint32_t ziglean_random_bytes(uint64_t len, ZigLeanRandomResult* out_result);
void ziglean_random_free(uint8_t* ptr, uint64_t len);

#ifdef __cplusplus
}
#endif

#endif
