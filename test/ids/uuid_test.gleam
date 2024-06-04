import gleam/bit_array
import gleam/erlang
import gleeunit/should
import ids/uuid

pub fn gen_v4_test() {
  let assert Ok(id) = uuid.generate_v4()

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
  >> = bit_array.from_string(id)

  should.be_true(True)
}

pub fn gen_v7_test() {
  let assert Ok(id_1) = uuid.generate_v7()

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
  >> = bit_array.from_string(id_1)

  should.be_true(True)
}

pub fn decode_v7_test() {
  let timestamp = erlang.system_time(erlang.Millisecond)
  let assert Ok(id) = uuid.generate_v7_from_timestamp(timestamp)

  let assert Ok(#(timestamp, version, _random_a, rfc_variant, _random_b)) =
    uuid.decode_v7(id)
  timestamp
  |> should.equal(timestamp)
  version
  |> should.equal(7)
  rfc_variant
  |> should.equal(2)

  uuid.decode_v7("123")
  |> should.be_error()
}
