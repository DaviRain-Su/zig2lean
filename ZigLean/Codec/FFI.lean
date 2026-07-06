namespace ZigLean.Codec.FFI

@[extern "lean_ziglean_codec_hex_encode_lower"]
opaque hexEncodeLowerRaw : @& ByteArray -> IO String

@[extern "lean_ziglean_codec_hex_decode"]
opaque hexDecodeRaw : @& String -> IO ByteArray

@[extern "lean_ziglean_codec_base64_encode"]
opaque base64EncodeRaw : @& ByteArray -> IO String

@[extern "lean_ziglean_codec_base64_decode"]
opaque base64DecodeRaw : @& String -> IO ByteArray

@[extern "lean_ziglean_codec_base64url_encode"]
opaque base64UrlEncodeRaw : @& ByteArray -> IO String

@[extern "lean_ziglean_codec_base64url_decode"]
opaque base64UrlDecodeRaw : @& String -> IO ByteArray

end ZigLean.Codec.FFI
