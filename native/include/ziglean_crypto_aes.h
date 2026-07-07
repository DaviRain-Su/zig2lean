#ifndef ZIGLEAN_CRYPTO_AES_H
#define ZIGLEAN_CRYPTO_AES_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define ZIGLEAN_AES256_KEY_LEN 32
#define ZIGLEAN_AES_BLOCK_LEN 16

typedef struct {
  uint32_t status;
  uint32_t reserved;
  uint64_t out_len;
  uint8_t* out;
} ZigLeanCipherResult;

// AES-256 in CTR mode. Encryption and decryption are identical.
uint32_t ziglean_crypto_aes256_ctr(
  const uint8_t* key,
  const uint8_t* iv,
  uint32_t iv_len,
  const uint8_t* input,
  uint64_t input_len,
  ZigLeanCipherResult* out_result
);

// AES-256 in CBC mode (PKCS#7 padding).
uint32_t ziglean_crypto_aes256_cbc_encrypt(
  const uint8_t* key,
  const uint8_t* iv,
  const uint8_t* input,
  uint64_t input_len,
  ZigLeanCipherResult* out_result
);

// AES-256 in CBC mode (PKCS#7 padding).
uint32_t ziglean_crypto_aes256_cbc_decrypt(
  const uint8_t* key,
  const uint8_t* iv,
  const uint8_t* input,
  uint64_t input_len,
  ZigLeanCipherResult* out_result
);

void ziglean_crypto_cipher_free(uint8_t* ptr, uint64_t len);

#ifdef __cplusplus
}
#endif

#endif
