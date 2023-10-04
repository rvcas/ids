//// A module for generating ULIDs (Universally Unique Lexicographically Sortable Identifier).

import gleam/string
import gleam/int
import gleam/result
import gleam/list
import gleam/bit_string
import gleam/erlang

const crockford_alphabet = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"

const max_time = 281_474_976_710_655

@external(erlang, "crypto", "strong_rand_bytes")
fn crypto_strong_rand_bytes(n: Int) -> BitString

/// Generates an ULID
pub fn generate() -> String {
  let timestamp = erlang.system_time(erlang.Millisecond)

  generate_from_timestamp(timestamp)
  |> fn(res) {
    case res {
      Ok(ulid) -> ulid
      _error -> panic as "Error: Couldn't generate ULID."
    }
  }
}

/// Generates an ULID using a unix timestamp in milliseconds
pub fn generate_from_timestamp(timestamp: Int) -> Result(String, String) {
  case timestamp {
    time if time <= max_time ->
      <<timestamp:size(48), crypto_strong_rand_bytes(10):bit_string>>
      |> encode_base32()
      |> Ok
    _other -> {
      let error =
        string.concat([
          "Error: The timestamp is too large. Use an Unix timestamp smaller than ",
          int.to_string(max_time),
          ".",
        ])
      Error(error)
    }
  }
}

/// Encode a bit_string using crockfords base32 encoding
pub fn encode_base32(bytes: BitString) -> String {
  // calculate how many bits to pad to make the bit_string divisible by 5
  let to_pad =
    bytes
    |> bit_string.byte_size()
    |> int.multiply(8)
    |> int.modulo(5)
    |> result.unwrap(5)
    |> int.subtract(5)
    |> int.absolute_value()
    |> int.modulo(5)
    |> result.unwrap(0)

  encode_bytes(<<bytes:bit_string, 0:size(to_pad)>>)
}

/// Recursively grabs 5 bits and uses them as index in the crockford alphabet and concatinates them to a string
fn encode_bytes(binary: BitString) -> String {
  case binary {
    <<index:unsigned-size(5), rest:bit_string>> -> {
      crockford_alphabet
      |> string.to_graphemes()
      |> list.at(index)
      |> result.unwrap("0")
      |> string.append(encode_bytes(rest))
    }
    <<>> -> ""
  }
}
