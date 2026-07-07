#ifndef ZIGLEAN_CRYPTO_STREAM_CIPHER_H
#define ZIGLEAN_CRYPTO_STREAM_CIPHER_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define ZIGLEAN_CHACHA20_KEY_LEN 32
#define ZIGLEAN_CHACHA20_NONCE_LEN 12
#define ZIGLEAN_XCHACHA20_KEY_LEN 32
#define ZIGLEAN_XCHACHA20_NONCE_LEN 24
#define ZIGLEAN_CHACHA20_LEGACY_KEY_LEN 32
#define ZIGLEAN_CHACHA20_LEGACY_NONCE_LEN 8

typedef struct {
  uint32_t status;
  uint32_t reserved;
  uint64_t out_len;
  uint8_t* out;
} ZigLeanStreamCipherResult;

// ChaCha20 (IETF variant, 12-byte nonce).
uint32_t ziglean_crypto_chacha20_xor(
  const uint8_t* key,
  const uint8_t* nonce,
  uint32_t counter,
  const uint8_t* input,
  uint64_t input_len,
  ZigLeanStreamCipherResult* out_result
);

// XChaCha20 (24-byte nonce).
uint32_t ziglean_crypto_xchacha20_xor(
  const uint8_t* key,
  const uint8_t* nonce,
  uint32_t counter,
  const uint8_t* input,
  uint64_t input_len,
  ZigLeanStreamCipherResult* out_result
);

// Original ChaCha20 variant (64-bit counter, 8-byte nonce).
uint32_t ziglean_crypto_chacha20_legacy_xor(
  const uint8_t* key,
  const uint8_t* nonce,
  uint64_t counter,
  const uint8_t* input,
  uint64_t input_len,
  ZigLeanStreamCipherResult* out_result
);

void ziglean_crypto_stream_cipher_free(uint8_t* ptr, uint64_t len);

#ifdef __cplusplus
}
#endif

#endif
