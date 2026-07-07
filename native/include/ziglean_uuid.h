#ifndef ZIGLEAN_UUID_H
#define ZIGLEAN_UUID_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
  uint32_t status;
  uint32_t reserved;
  uint64_t out_len;
  uint8_t* out;
} ZigLeanUuidResult;

uint32_t ziglean_uuid_v4(ZigLeanUuidResult* out_result);
void ziglean_uuid_free(uint8_t* ptr, uint64_t len);

#ifdef __cplusplus
}
#endif

#endif
