import ZigLean

open ZigLean

def bytes (s : String) : ByteArray :=
  s.toUTF8

def assertEq [BEq α] [ToString α] (name : String) (actual expected : α) : IO Unit := do
  if actual != expected then
    throw <| IO.userError s!"{name}: expected {expected}, got {actual}"

def main : IO Unit := do
  assertEq "stub validate" (← Json.validate (bytes "{}")) true
