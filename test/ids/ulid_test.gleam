import ids/ulid
import gleeunit/should
import gleam/string
import gleam/list

const crockford_alphabet = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"

pub fn gen_test() {
  let ulid_1 = ulid.generate()
  check_length(ulid_1)
  check_starting_character(ulid_1)
  check_crockford_characters(ulid_1)

  let assert Ok(ulid_2) = ulid.generate_from_timestamp(1_696_346_659_217)
  check_length(ulid_2)
  check_starting_character(ulid_2)
  check_crockford_characters(ulid_2)

  ulid.generate_from_timestamp(281_474_976_710_656)
  |> should.be_error()
}

fn check_length(ulid) -> Nil {
  ulid
  |> string.length()
  |> should.equal(26)
}

fn check_starting_character(ulid) -> Nil {
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
}

fn check_crockford_characters(ulid) -> Nil {
  ulid
  |> string.to_graphemes()
  |> list.all(fn(x) {
    crockford_alphabet
    |> string.to_graphemes()
    |> list.contains(x)
  })
  |> should.be_true()
}
