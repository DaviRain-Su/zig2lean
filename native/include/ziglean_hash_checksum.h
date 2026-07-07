#ifndef ZIGLEAN_HASH_CHECKSUM_H
#define ZIGLEAN_HASH_CHECKSUM_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

uint32_t ziglean_hash_crc32(const uint8_t* input, uint64_t input_len, uint32_t* out_crc);
uint32_t ziglean_hash_adler32(const uint8_t* input, uint64_t input_len, uint32_t* out_adler);
uint32_t ziglean_hash_xxhash64(uint64_t seed, const uint8_t* input, uint64_t input_len, uint64_t* out_hash);

#ifdef __cplusplus
}
#endif

#endif