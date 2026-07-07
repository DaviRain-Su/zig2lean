import ZigLean

namespace RandomTest

open ZigLean.Random

def assertEq [BEq α] [ToString α] (name : String) (actual expected : α) : IO Unit := do
  if actual != expected then
    throw <| IO.userError s!"{name}: expected {expected}, got {actual}"

def main : IO Unit := do
  let empty ← randomBytes 0
  assertEq "random bytes 0 length" empty.size 0

  let sixteen ← randomBytes 16
  assertEq "random bytes 16 length" sixteen.size 16

  let thirtyTwo ← randomBytes 32
  assertEq "random bytes 32 length" thirtyTwo.size 32

  let a ← randomBytes 32
  let b ← randomBytes 32
  if a == b then
    throw <| IO.userError "random bytes should differ between calls"

end RandomTest

def main : IO Unit :=
  RandomTest.main
