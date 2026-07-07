#ifndef ZIGLEAN_CODEC_H
#define ZIGLEAN_CODEC_H

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
} ZigLeanCodecResult;

uint32_t ziglean_codec_hex_encode_lower(const uint8_t* input, uint64_t input_len, ZigLeanCodecResult* out_result);
uint32_t ziglean_codec_hex_decode(const uint8_t* input, uint64_t input_len, ZigLeanCodecResult* out_result);
uint32_t ziglean_codec_base64_encode(const uint8_t* input, uint64_t input_len, ZigLeanCodecResult* out_result);
uint32_t ziglean_codec_base64_decode(const uint8_t* input, uint64_t input_len, ZigLeanCodecResult* out_result);
uint32_t ziglean_codec_base64url_encode(const uint8_t* input, uint64_t input_len, ZigLeanCodecResult* out_result);
uint32_t ziglean_codec_base64url_decode(const uint8_t* input, uint64_t input_len, ZigLeanCodecResult* out_result);
uint32_t ziglean_codec_base58_encode(const uint8_t* input, uint64_t input_len, ZigLeanCodecResult* out_result);
uint32_t ziglean_codec_base58_decode(const uint8_t* input, uint64_t input_len, ZigLeanCodecResult* out_result);
uint32_t ziglean_codec_base32_encode(const uint8_t* input, uint64_t input_len, ZigLeanCodecResult* out_result);
uint32_t ziglean_codec_base32_decode(const uint8_t* input, uint64_t input_len, ZigLeanCodecResult* out_result);
uint32_t ziglean_codec_hex_encode_upper(const uint8_t* input, uint64_t input_len, ZigLeanCodecResult* out_result);
uint32_t ziglean_codec_base85_encode(const uint8_t* input, uint64_t input_len, ZigLeanCodecResult* out_result);
uint32_t ziglean_codec_base85_decode(const uint8_t* input, uint64_t input_len, ZigLeanCodecResult* out_result);
uint32_t ziglean_codec_timing_safe_eq(const uint8_t* a, uint64_t a_len, const uint8_t* b, uint64_t b_len);
void ziglean_codec_free(uint8_t* ptr, uint64_t len);

#ifdef __cplusplus
}
#endif

#endif
