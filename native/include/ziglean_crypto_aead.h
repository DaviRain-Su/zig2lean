#ifndef ZIGLEAN_CRYPTO_AEAD_H
#define ZIGLEAN_CRYPTO_AEAD_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define ZIGLEAN_AES256GCM_KEY_LEN 32
#define ZIGLEAN_AES256GCM_NONCE_LEN 12
#define ZIGLEAN_AES256GCM_TAG_LEN 16
#define ZIGLEAN_AES256GCMSIV_KEY_LEN 32
#define ZIGLEAN_AES256GCMSIV_NONCE_LEN 12
#define ZIGLEAN_AES256GCMSIV_TAG_LEN 16
#define ZIGLEAN_AEGIS256_KEY_LEN 32
#define ZIGLEAN_AEGIS256_NONCE_LEN 32
#define ZIGLEAN_AEGIS256_TAG_LEN 16
#define ZIGLEAN_CHACHA20POLY1305_KEY_LEN 32
#define ZIGLEAN_CHACHA20POLY1305_NONCE_LEN 12
#define ZIGLEAN_CHACHA20POLY1305_TAG_LEN 16

typedef struct {
  uint32_t status;
  uint32_t reserved;
  uint64_t out_len;
  uint64_t error_offset;
  uint8_t* out;
} ZigLeanAeadResult;

uint32_t ziglean_crypto_aes256gcm_encrypt(
  const uint8_t* key,
  const uint8_t* nonce,
  const uint8_t* aad,
  uint64_t aad_len,
  const uint8_t* plaintext,
  uint64_t plaintext_len,
  ZigLeanAeadResult* out_result
);

uint32_t ziglean_crypto_aes256gcm_decrypt(
  const uint8_t* key,
  const uint8_t* nonce,
  const uint8_t* aad,
  uint64_t aad_len,
  const uint8_t* ciphertext_and_tag,
  uint64_t ciphertext_and_tag_len,
  ZigLeanAeadResult* out_result
);

uint32_t ziglean_crypto_aes256gcmsiv_encrypt(
  const uint8_t* key,
  const uint8_t* nonce,
  const uint8_t* aad,
  uint64_t aad_len,
  const uint8_t* plaintext,
  uint64_t plaintext_len,
  ZigLeanAeadResult* out_result
);

uint32_t ziglean_crypto_aes256gcmsiv_decrypt(
  const uint8_t* key,
  const uint8_t* nonce,
  const uint8_t* aad,
  uint64_t aad_len,
  const uint8_t* ciphertext_and_tag,
  uint64_t ciphertext_and_tag_len,
  ZigLeanAeadResult* out_result
);

uint32_t ziglean_crypto_aegis256_encrypt(
  const uint8_t* key,
  const uint8_t* nonce,
  const uint8_t* aad,
  uint64_t aad_len,
  const uint8_t* plaintext,
  uint64_t plaintext_len,
  ZigLeanAeadResult* out_result
);

uint32_t ziglean_crypto_aegis256_decrypt(
  const uint8_t* key,
  const uint8_t* nonce,
  const uint8_t* aad,
  uint64_t aad_len,
  const uint8_t* ciphertext_and_tag,
  uint64_t ciphertext_and_tag_len,
  ZigLeanAeadResult* out_result
);

uint32_t ziglean_crypto_chacha20poly1305_encrypt(
  const uint8_t* key,
  const uint8_t* nonce,
  const uint8_t* aad,
  uint64_t aad_len,
  const uint8_t* plaintext,
  uint64_t plaintext_len,
  ZigLeanAeadResult* out_result
);

uint32_t ziglean_crypto_chacha20poly1305_decrypt(
  const uint8_t* key,
  const uint8_t* nonce,
  const uint8_t* aad,
  uint64_t aad_len,
  const uint8_t* ciphertext_and_tag,
  uint64_t ciphertext_and_tag_len,
  ZigLeanAeadResult* out_result
);

uint32_t ziglean_crypto_aes256ocb_encrypt(
  const uint8_t* key,
  const uint8_t* nonce,
  const uint8_t* aad,
  uint64_t aad_len,
  const uint8_t* plaintext,
  uint64_t plaintext_len,
  ZigLeanAeadResult* out_result
);

uint32_t ziglean_crypto_aes256ocb_decrypt(
  const uint8_t* key,
  const uint8_t* nonce,
  const uint8_t* aad,
  uint64_t aad_len,
  const uint8_t* ciphertext_and_tag,
  uint64_t ciphertext_and_tag_len,
  ZigLeanAeadResult* out_result
);

uint32_t ziglean_crypto_aes256siv_encrypt(
  const uint8_t* key,
  const uint8_t* nonce,
  uint64_t nonce_len,
  const uint8_t* aad,
  uint64_t aad_len,
  const uint8_t* plaintext,
  uint64_t plaintext_len,
  ZigLeanAeadResult* out_result
);

uint32_t ziglean_crypto_aes256siv_decrypt(
  const uint8_t* key,
  const uint8_t* nonce,
  uint64_t nonce_len,
  const uint8_t* aad,
  uint64_t aad_len,
  const uint8_t* ciphertext_and_tag,
  uint64_t ciphertext_and_tag_len,
  ZigLeanAeadResult* out_result
);

void ziglean_crypto_aead_free(uint8_t* ptr, uint64_t len);

#ifdef __cplusplus
}
#endif

#endif