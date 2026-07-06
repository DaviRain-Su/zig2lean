#ifndef ZIGLEAN_COMPRESS_H
#define ZIGLEAN_COMPRESS_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
  uint32_t status;
  uint32_t reserved;
  uint64_t out_len;
  uint64_t error_offset;
  uint8_t* out;
} ZigLeanCompressResult;

uint32_t ziglean_compress_gzip(const uint8_t* input, uint64_t input_len, ZigLeanCompressResult* out_result);
uint32_t ziglean_compress_gzip_decompress(const uint8_t* input, uint64_t input_len, ZigLeanCompressResult* out_result);
uint32_t ziglean_compress_zlib(const uint8_t* input, uint64_t input_len, ZigLeanCompressResult* out_result);
uint32_t ziglean_compress_zlib_decompress(const uint8_t* input, uint64_t input_len, ZigLeanCompressResult* out_result);
uint32_t ziglean_compress_deflate(const uint8_t* input, uint64_t input_len, ZigLeanCompressResult* out_result);
uint32_t ziglean_compress_deflate_decompress(const uint8_t* input, uint64_t input_len, ZigLeanCompressResult* out_result);
void ziglean_compress_free(uint8_t* ptr, uint64_t len);

#ifdef __cplusplus
}
#endif

#endif