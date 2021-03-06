import ids/uuid
import gleam/bit_string
import gleam/io
import gleam/should

pub fn gen_test() {
  assert <<
    _:size(64),
    45,
    _:size(32),
    45,
    _:size(32),
    45,
    _:size(32),
    45,
    _:size(96),
  >> =
    uuid.v4()
    |> bit_string.from_string()

  should.be_true(True)
}
