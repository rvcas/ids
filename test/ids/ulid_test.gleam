import gleam/list
import gleam/result
import gleam/string
import gleeunit/should
import ids/ulid

@external(erlang, "binary", "decode_unsigned")
fn decode_unsigned(b: BitArray) -> Int

pub fn gen_test() {
  let id = ulid.generate()
  id
  |> check_length()
  |> check_starting_character()
  |> check_crockford_characters()
}

pub fn from_timestamp_test() {
  let assert Ok(id_1) = ulid.from_timestamp(1_696_346_659_217)
  id_1
  |> check_length()
  |> check_starting_character()
  |> check_crockford_characters()

  let assert Ok(id_2) = ulid.from_timestamp(281_474_976_710_655)
  id_2
  |> string.starts_with("7ZZZZZZZZZ")
  |> should.be_true()
}

pub fn from_parts_test() {
  let assert Ok(id_1) =
    ulid.from_parts(1_696_346_659_217, <<
      150, 184, 121, 192, 42, 76, 148, 57, 61, 61,
    >>)
  id_1
  |> should.equal("01HBV27PCHJTW7KG1A9JA3JF9X")

  let assert Ok(id_2) =
    ulid.from_parts(281_474_976_710_655, <<
      255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    >>)
  id_2
  |> should.equal("7ZZZZZZZZZZZZZZZZZZZZZZZZZ")
}

pub fn decode_test() {
  let timestamp = 1_696_346_659_217
  let random = <<150, 184, 121, 192, 42, 76, 148, 57, 61, 61>>

  let assert Ok(#(decode_timestamp, randomness)) =
    ulid.from_parts(timestamp, random)
    |> result.then(ulid.decode)
  decode_timestamp
  |> should.equal(timestamp)
  randomness
  |> should.equal(random)

  let assert Ok(#(decode_max_time, randomness)) =
    ulid.decode("7ZZZZZZZZZZZZZZZZZZZZZZZZZ")
  decode_max_time
  |> should.equal(ulid.max_time)
  randomness
  |> should.equal(<<255, 255, 255, 255, 255, 255, 255, 255, 255, 255>>)

  ulid.decode("8ZZZZZZZZZZZZZZZZZZZZZZZZZ")
  |> should.be_error()
}

pub fn monotonicity_test() {
  let assert Ok(actor) = ulid.start()

  let assert Ok(id_1) = ulid.monotonic_generate(actor)
  id_1
  |> check_length()
  |> check_starting_character()
  |> check_crockford_characters()

  let timestamp = 1_696_346_660_217
  let assert Ok(#(_, random_1)) =
    ulid.monotonic_from_timestamp(actor, timestamp)
    |> result.then(ulid.decode)
  let assert Ok(#(_, random_2)) =
    ulid.monotonic_from_timestamp(actor, timestamp)
    |> result.then(ulid.decode)

  random_2
  |> decode_unsigned()
  |> should.equal({ decode_unsigned(random_1) + 1 })
}

fn check_length(ulid) -> String {
  ulid
  |> string.length()
  |> should.equal(26)

  ulid
}

fn check_starting_character(ulid) -> String {
  ulid
  |> string.first()
  |> fn(x) {
    case x {
      Ok(y) ->
        "01234567"
        |> string.to_graphemes()
        |> list.contains(y)
      _error -> False
    }
  }
  |> should.be_true()

  ulid
}

fn check_crockford_characters(ulid) -> String {
  ulid
  |> string.to_graphemes()
  |> list.all(fn(x) {
    ulid.crockford_alphabet
    |> string.to_graphemes()
    |> list.contains(x)
  })
  |> should.be_true()

  ulid
}
