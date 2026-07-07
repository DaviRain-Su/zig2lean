#ifndef ZIGLEAN_CRYPTO_SIGN_H
#define ZIGLEAN_CRYPTO_SIGN_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define ZIGLEAN_ED25519_SEED_LEN 32
#define ZIGLEAN_ED25519_PUBLIC_KEY_LEN 32
#define ZIGLEAN_ED25519_SIGNATURE_LEN 64
#define ZIGLEAN_SECP256K1_SECRET_KEY_LEN 32
#define ZIGLEAN_SECP256K1_PUBLIC_KEY_LEN 33
#define ZIGLEAN_SECP256K1_SIGNATURE_LEN 64
#define ZIGLEAN_P256_SEED_LEN 32
#define ZIGLEAN_P256_PUBLIC_KEY_LEN 33
#define ZIGLEAN_P256_SIGNATURE_LEN 64

uint32_t ziglean_crypto_ed25519_sign(
  const uint8_t* seed,
  const uint8_t* message,
  uint64_t message_len,
  uint8_t* out_signature
);

uint32_t ziglean_crypto_ed25519_verify(
  const uint8_t* public_key,
  const uint8_t* message,
  uint64_t message_len,
  const uint8_t* signature,
  uint32_t* out_valid
);

uint32_t ziglean_crypto_secp256k1_sign(
  const uint8_t* secret_key,
  const uint8_t* message,
  uint64_t message_len,
  uint8_t* out_signature
);

uint32_t ziglean_crypto_secp256k1_verify(
  const uint8_t* public_key,
  uint64_t public_key_len,
  const uint8_t* message,
  uint64_t message_len,
  const uint8_t* signature,
  uint32_t* out_valid
);

uint32_t ziglean_crypto_p256_sign(
  const uint8_t* seed,
  const uint8_t* message,
  uint64_t message_len,
  uint8_t* out_signature
);

uint32_t ziglean_crypto_p256_verify(
  const uint8_t* public_key,
  uint64_t public_key_len,
  const uint8_t* message,
  uint64_t message_len,
  const uint8_t* signature,
  uint32_t* out_valid
);

#ifdef __cplusplus
}
#endif

#endif