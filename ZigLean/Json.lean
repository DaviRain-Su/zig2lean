import ZigLean.Json.FFI

namespace ZigLean.Json

def validate (input : ByteArray) : IO Bool := do
  pure ((← FFI.validateRaw input) == 0)

end ZigLean.Json
