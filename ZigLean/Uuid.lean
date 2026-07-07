import ZigLean.Uuid.FFI

namespace ZigLean.Uuid

def uuid4 : IO String :=
  FFI.uuid4Raw

end ZigLean.Uuid
