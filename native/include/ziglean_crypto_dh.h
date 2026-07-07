#ifndef ZIGLEAN_CRYPTO_DH_H
#define ZIGLEAN_CRYPTO_DH_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define ZIGLEAN_X25519_SEED_LEN 32
#define ZIGLEAN_X25519_SECRET_KEY_LEN 32
#define ZIGLEAN_X25519_PUBLIC_KEY_LEN 32
#define ZIGLEAN_X25519_KEYPAIR_LEN 64
#define ZIGLEAN_X25519_SHARED_SECRET_LEN 32

uint32_t ziglean_crypto_x25519_keypair(
  const uint8_t* seed,
  uint8_t* out_keypair
);

uint32_t ziglean_crypto_x25519_shared_secret(
  const uint8_t* secret_key,
  const uint8_t* public_key,
  uint8_t* out_shared_secret
);

#ifdef __cplusplus
}
#endif

#endif
