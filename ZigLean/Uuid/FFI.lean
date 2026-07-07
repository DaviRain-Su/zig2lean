namespace ZigLean.Uuid.FFI

@[extern "lean_ziglean_uuid_v4"]
opaque uuid4Raw : IO String

end ZigLean.Uuid.FFI
