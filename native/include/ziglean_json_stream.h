#ifndef ZIGLEAN_JSON_STREAM_H
#define ZIGLEAN_JSON_STREAM_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define ZIGLEAN_JSON_STREAM_TOKEN 0
#define ZIGLEAN_JSON_STREAM_NEED_MORE 1
#define ZIGLEAN_JSON_STREAM_ERROR 2
#define ZIGLEAN_JSON_STREAM_END 3

typedef struct {
  uint32_t status;
  uint32_t kind;
  uint64_t offset;
  uint64_t length;
  uint64_t error_offset;
} ZigLeanJsonStreamResult;

uint32_t ziglean_json_stream_init(void** out_handle);

uint32_t ziglean_json_stream_feed(void* handle, const uint8_t* input, uint64_t input_len);

void ziglean_json_stream_end_input(void* handle);

uint32_t ziglean_json_stream_next(void* handle, ZigLeanJsonStreamResult* out_result);

void ziglean_json_stream_free(void* handle);

#ifdef __cplusplus
}
#endif

#endif