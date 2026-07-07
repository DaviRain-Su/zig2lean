#ifndef ZIGLEAN_CRYPTO_HASH_H
#define ZIGLEAN_CRYPTO_HASH_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define ZIGLEAN_CRYPTO_SHA1_LEN 20
#define ZIGLEAN_CRYPTO_SHA224_LEN 28
#define ZIGLEAN_CRYPTO_SHA256_LEN 32
#define ZIGLEAN_CRYPTO_SHA384_LEN 48
#define ZIGLEAN_CRYPTO_SHA512_LEN 64
#define ZIGLEAN_CRYPTO_SHA3_224_LEN 28
#define ZIGLEAN_CRYPTO_SHA3_256_LEN 32
#define ZIGLEAN_CRYPTO_SHA3_384_LEN 48
#define ZIGLEAN_CRYPTO_SHA3_512_LEN 64
#define ZIGLEAN_CRYPTO_KECCAK256_LEN 32
#define ZIGLEAN_CRYPTO_KECCAK512_LEN 64
#define ZIGLEAN_CRYPTO_SIPHASH64_LEN 8
#define ZIGLEAN_CRYPTO_BLAKE3_LEN 32
#define ZIGLEAN_CRYPTO_BLAKE2B256_LEN 32
#define ZIGLEAN_CRYPTO_BLAKE2S256_LEN 32
#define ZIGLEAN_CRYPTO_BLAKE2B512_LEN 64
#define ZIGLEAN_CRYPTO_HMAC_SHA224_LEN 28
#define ZIGLEAN_CRYPTO_HMAC_SHA256_LEN 32
#define ZIGLEAN_CRYPTO_HMAC_SHA384_LEN 48
#define ZIGLEAN_CRYPTO_HMAC_SHA512_LEN 64

uint32_t ziglean_crypto_sha1(
  const uint8_t* input,
  uint64_t input_len,
  uint8_t* out_digest
);

uint32_t ziglean_crypto_sha224(
  const uint8_t* input,
  uint64_t input_len,
  uint8_t* out_digest
);

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

uint32_t ziglean_crypto_blake2b256(
  const uint8_t* input,
  uint64_t input_len,
  uint8_t* out_digest
);

uint32_t ziglean_crypto_blake2s256(
  const uint8_t* input,
  uint64_t input_len,
  uint8_t* out_digest
);

uint32_t ziglean_crypto_blake2b512(
  const uint8_t* input,
  uint64_t input_len,
  uint8_t* out_digest
);

uint32_t ziglean_crypto_hmac_sha224(
  const uint8_t* key,
  uint64_t key_len,
  const uint8_t* message,
  uint64_t message_len,
  uint8_t* out_mac
);

uint32_t ziglean_crypto_hmac_sha256(
  const uint8_t* key,
  uint64_t key_len,
  const uint8_t* message,
  uint64_t message_len,
  uint8_t* out_mac
);

uint32_t ziglean_crypto_hmac_sha384(
  const uint8_t* key,
  uint64_t key_len,
  const uint8_t* message,
  uint64_t message_len,
  uint8_t* out_mac
);

uint32_t ziglean_crypto_hmac_sha512(
  const uint8_t* key,
  uint64_t key_len,
  const uint8_t* message,
  uint64_t message_len,
  uint8_t* out_mac
);

uint32_t ziglean_crypto_sha384(
  const uint8_t* input,
  uint64_t input_len,
  uint8_t* out_digest
);

uint32_t ziglean_crypto_sha512(
  const uint8_t* input,
  uint64_t input_len,
  uint8_t* out_digest
);

uint32_t ziglean_crypto_sha3_224(
  const uint8_t* input,
  uint64_t input_len,
  uint8_t* out_digest
);

uint32_t ziglean_crypto_sha3_256(
  const uint8_t* input,
  uint64_t input_len,
  uint8_t* out_digest
);

uint32_t ziglean_crypto_sha3_384(
  const uint8_t* input,
  uint64_t input_len,
  uint8_t* out_digest
);

uint32_t ziglean_crypto_sha3_512(
  const uint8_t* input,
  uint64_t input_len,
  uint8_t* out_digest
);

uint32_t ziglean_crypto_keccak256(
  const uint8_t* input,
  uint64_t input_len,
  uint8_t* out_digest
);

uint32_t ziglean_crypto_keccak512(
  const uint8_t* input,
  uint64_t input_len,
  uint8_t* out_digest
);

uint32_t ziglean_crypto_siphash64(
  const uint8_t* key,
  const uint8_t* input,
  uint64_t input_len,
  uint8_t* out_hash
);

#ifdef __cplusplus
}
#endif

#endif
