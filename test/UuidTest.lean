import ZigLean

namespace UuidTest

open ZigLean.Uuid

instance : GetElem String Nat Char (fun _ _ => True) where
  getElem s i _ := s.toList.getD i '\u0000'

def assertEq [BEq α] [ToString α] (name : String) (actual expected : α) : IO Unit := do
  if actual != expected then
    throw <| IO.userError s!"{name}: expected {expected}, got {actual}"

def isValidUuid4 (s : String) : Bool :=
  s.length == 36 &&
  s[8] == '-' && s[13] == '-' && s[18] == '-' && s[23] == '-' &&
  s[14] == '4' &&
  (s[19] == '8' || s[19] == '9' || s[19] == 'a' || s[19] == 'b')

def main : IO Unit := do
  let u1 ← uuid4
  assertEq "uuid4 length" u1.length 36
  unless isValidUuid4 u1 do
    throw <| IO.userError s!"uuid4 format invalid: {u1}"

  let u2 ← uuid4
  if u1 == u2 then
    throw <| IO.userError "uuid4 values should differ between calls"

end UuidTest

def main : IO Unit :=
  UuidTest.main
