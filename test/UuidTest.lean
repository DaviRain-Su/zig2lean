import ZigLean

namespace UuidTest

open ZigLean.Uuid

def assertEq [BEq α] [ToString α] (name : String) (actual expected : α) : IO Unit := do
  if actual != expected then
    throw <| IO.userError s!"{name}: expected {expected}, got {actual}"

def isHexDigit (c : Char) : Bool :=
  (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f')

def isValidUuid4 (s : String) : Bool :=
  let chars := s.toList
  s.length == 36 &&
  chars.getD 8 '\u0000' == '-' && chars.getD 13 '\u0000' == '-' && chars.getD 18 '\u0000' == '-' && chars.getD 23 '\u0000' == '-' &&
  chars.getD 14 '\u0000' == '4' &&
  (chars.getD 19 '\u0000' == '8' || chars.getD 19 '\u0000' == '9' || chars.getD 19 '\u0000' == 'a' || chars.getD 19 '\u0000' == 'b') &&
  chars.all (fun c => c == '-' || isHexDigit c)

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
