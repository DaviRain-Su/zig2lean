#ifndef ZIGLEAN_CRYPTO_KDF_H
#define ZIGLEAN_CRYPTO_KDF_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

uint32_t ziglean_crypto_hkdf_sha256(
  const uint8_t* salt,
  uint64_t salt_len,
  const uint8_t* ikm,
  uint64_t ikm_len,
  const uint8_t* info,
  uint64_t info_len,
  uint64_t out_len,
  uint8_t** out_bytes
);

uint32_t ziglean_crypto_pbkdf2_sha256(
  const uint8_t* password,
  uint64_t password_len,
  const uint8_t* salt,
  uint64_t salt_len,
  uint32_t rounds,
  uint64_t out_len,
  uint8_t** out_bytes
);

void ziglean_crypto_kdf_free(uint8_t* ptr, uint64_t len);

#ifdef __cplusplus
}
#endif

#endif