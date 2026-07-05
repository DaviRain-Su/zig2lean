#ifndef ZIGLEAN_JSON_H
#define ZIGLEAN_JSON_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
  uint32_t kind;
  uint32_t reserved;
  uint64_t offset;
  uint64_t length;
} ZigLeanJsonToken;

typedef struct {
  uint32_t code;
  uint32_t reserved;
  uint64_t offset;
} ZigLeanJsonError;

uint32_t ziglean_json_validate(const uint8_t* input, uint64_t input_len);

uint32_t ziglean_json_parse_tokens(
  const uint8_t* input,
  uint64_t input_len,
  ZigLeanJsonToken** out_tokens,
  uint64_t* out_len,
  ZigLeanJsonError* out_error
);

void ziglean_json_free_tokens(ZigLeanJsonToken* tokens, uint64_t len);

#ifdef __cplusplus
}
#endif

#endif
