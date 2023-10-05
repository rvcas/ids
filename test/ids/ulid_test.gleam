import ids/ulid
import gleeunit/should
import gleam/string
import gleam/list

pub fn gen_test() {
  let ulid_1 = ulid.generate()
  ulid_1
  |> check_length()
  |> check_starting_character()
  |> check_crockford_characters()

  let assert Ok(ulid_2) = ulid.generate_from_timestamp(1_696_346_659_217)
  ulid_2
  |> check_length()
  |> check_starting_character()
  |> check_crockford_characters()

  let assert Ok(ulid_3) = ulid.generate_from_timestamp(281_474_976_710_655)
  ulid_3
  |> string.starts_with("7ZZZZZZZZZ")
  |> should.be_true()
}

pub fn decode_test() {
  let timestamp = 1_696_346_659_217

  let assert Ok(ulid) = ulid.generate_from_timestamp(timestamp)
  let assert Ok(#(decode_timestamp, _randomness)) = ulid.decode(ulid)
  decode_timestamp
  |> should.equal(timestamp)

  let assert Ok(#(decode_max_time, randomness)) =
    ulid.decode("7ZZZZZZZZZZZZZZZZZZZZZZZZZ")
  decode_max_time
  |> should.equal(ulid.max_time)

  randomness
  |> should.equal(<<255, 255, 255, 255, 255, 255, 255, 255, 255, 255>>)
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
