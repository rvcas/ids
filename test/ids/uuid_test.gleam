import gleeunit/should
import ids/uuid
import gleam/bit_string

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
  >> = bit_string.from_string(id)

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
  >> = bit_string.from_string(id_1)

  should.be_true(True)
}
