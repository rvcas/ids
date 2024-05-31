import gleam/bit_array
import gleam/string
import gleeunit/should
import ids/typeid

pub fn gen_test() {
  typeid.generate("test")
  |> should.be_ok

  typeid.generate("te_st")
  |> should.be_ok

  typeid.generate("123")
  |> should.be_error

  let assert Ok(id) = typeid.generate("test")

  id
  |> string.starts_with("test_")
  |> should.be_true

  id
  |> string.length
  |> should.equal(31)
}

pub fn gen_empty_prefix_test() {
  let assert Ok(id) = typeid.generate("")

  id
  |> string.contains("_")
  |> should.be_false

  id
  |> string.length
  |> should.equal(26)
}

pub fn from_uuid_test() {
  typeid.from_uuid("test", "wobble")
  |> should.be_error

  typeid.from_uuid("test", "018fcec0-b44b-7ce2-b187-2f08349beab9")
  |> should.be_ok

  let assert Ok(id) =
    typeid.from_uuid("test", "018fcec0-b44b-7ce2-b187-2f08349beab9")

  id
  |> should.equal("test_01hz7c1d2bfkhb31sf10t9qtns")
}

pub fn decode_test() {
  let assert Ok(id1) = typeid.generate("test")
  let assert Ok(id2) = typeid.generate("")
  let assert Ok(id3) =
    typeid.from_uuid("test", "018fcec0-b44b-7ce2-b187-2f08349beab9")

  id1
  |> typeid.decode
  |> should.be_ok

  id2
  |> typeid.decode
  |> should.be_ok

  ""
  |> typeid.decode
  |> should.be_error

  "lkjgijkldsa"
  |> typeid.decode
  |> should.be_error

  let assert Ok(#(prefix1, suffix1)) = typeid.decode(id1)
  let assert Ok(#(prefix2, _suffix2)) = typeid.decode(id2)
  let assert Ok(#(_prefix3, suffix3)) = typeid.decode(id3)

  prefix1
  |> should.equal("test")

  prefix2
  |> should.equal("")

  let assert <<
    _:size(64),
    45,
    _:size(32),
    45,
    _:size(32),
    45,
    _:size(32),
    45,
    _:size(96),
  >> = bit_array.from_string(suffix1)

  suffix3
  |> should.equal("018fcec0-b44b-7ce2-b187-2f08349beab9")
}
