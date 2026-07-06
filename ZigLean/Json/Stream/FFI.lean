namespace ZigLean.Json.Stream.FFI

@[extern "lean_ziglean_json_stream_init"]
opaque initRaw : IO USize

@[extern "lean_ziglean_json_stream_feed"]
opaque feedRaw : USize -> @& ByteArray -> IO Unit

@[extern "lean_ziglean_json_stream_end_input"]
opaque endInputRaw : USize -> IO Unit

@[extern "lean_ziglean_json_stream_next"]
opaque nextRaw : USize -> IO ByteArray

@[extern "lean_ziglean_json_stream_free"]
opaque freeRaw : USize -> IO Unit

end ZigLean.Json.Stream.FFI