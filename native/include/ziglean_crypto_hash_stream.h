#ifndef ZIGLEAN_CRYPTO_HASH_STREAM_H
#define ZIGLEAN_CRYPTO_HASH_STREAM_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define ZIGLEAN_HASH_STREAM_SHA256 1
#define ZIGLEAN_HASH_STREAM_BLAKE3 2
#define ZIGLEAN_HASH_STREAM_SHA512 3
#define ZIGLEAN_HASH_STREAM_SHA3_256 4
#define ZIGLEAN_HASH_STREAM_KECCAK256 5

#define ZIGLEAN_HASH_STREAM_SHA256_LEN 32
#define ZIGLEAN_HASH_STREAM_BLAKE3_LEN 32
#define ZIGLEAN_HASH_STREAM_SHA512_LEN 64
#define ZIGLEAN_HASH_STREAM_SHA3_256_LEN 32
#define ZIGLEAN_HASH_STREAM_KECCAK256_LEN 32

uint32_t ziglean_crypto_hash_stream_digest_len(uint32_t algo, uint64_t* out_len);

uint32_t ziglean_crypto_hash_stream_init(uint32_t algo, void** out_handle);

uint32_t ziglean_crypto_hash_stream_update(
  void* handle,
  const uint8_t* input,
  uint64_t input_len
);

uint32_t ziglean_crypto_hash_stream_final(
  void* handle,
  uint8_t* out_digest,
  uint64_t out_len
);

void ziglean_crypto_hash_stream_free(void* handle);

#ifdef __cplusplus
}
#endif

#endif