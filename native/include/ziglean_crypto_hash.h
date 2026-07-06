#ifndef ZIGLEAN_CRYPTO_HASH_H
#define ZIGLEAN_CRYPTO_HASH_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define ZIGLEAN_CRYPTO_SHA256_LEN 32
#define ZIGLEAN_CRYPTO_BLAKE3_LEN 32
#define ZIGLEAN_CRYPTO_HMAC_SHA256_LEN 32

uint32_t ziglean_crypto_sha256(
  const uint8_t* input,
  uint64_t input_len,
  uint8_t* out_digest
);

uint32_t ziglean_crypto_blake3(
  const uint8_t* input,
  uint64_t input_len,
  uint8_t* out_digest
);

uint32_t ziglean_crypto_hmac_sha256(
  const uint8_t* key,
  uint64_t key_len,
  const uint8_t* message,
  uint64_t message_len,
  uint8_t* out_mac
);

#ifdef __cplusplus
}
#endif

#endif
