//// A module for generating ULIDs (Universally Unique Lexicographically Sortable Identifier).

import gleam/string
import gleam/int
import gleam/result
import gleam/list
import gleam/erlang

pub const crockford_alphabet = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"

pub const max_time = 281_474_976_710_655

@external(erlang, "crypto", "strong_rand_bytes")
fn crypto_strong_rand_bytes(n: Int) -> BitString

@external(erlang, "erlang", "bit_size")
fn bit_size(b: BitString) -> Int

/// Generates an ULID.
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

/// Generates an ULID using a unix timestamp in milliseconds.
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

/// Decodes an ULID into #(timestamp, randomness).
pub fn decode(ulid: String) -> Result(#(Int, BitString), String) {
  case decode_base32(ulid) {
    Ok(<<timestamp:unsigned-size(48), randomness:bit_string-size(80)>>) ->
      Ok(#(timestamp, randomness))
    _other -> Error("Error: Decoding failed. Is a valid ULID being supplied?")
  }
}

/// Encode a bit_string using crockfords base32 encoding.
fn encode_base32(bytes: BitString) -> String {
  // calculate how many bits to pad to make the bit_string divisible by 5
  let to_pad =
    bytes
    |> bit_size()
    |> int.modulo(5)
    |> result.unwrap(5)
    |> int.subtract(5)
    |> int.absolute_value()
    |> int.modulo(5)
    |> result.unwrap(0)

  encode_bytes(<<0:size(to_pad), bytes:bit_string>>)
}

/// Recursively grabs 5 bits and uses them as index in the crockford alphabet and concatinates them to a string.
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

/// Decode a string using crockford's base32 encoding.
fn decode_base32(binary: String) -> Result(BitString, Nil) {
  let crockford_with_index =
    crockford_alphabet
    |> string.to_graphemes()
    |> list.index_map(fn(i, x) { #(x, i) })

  let bits =
    binary
    |> string.to_graphemes()
    |> list.fold(
      <<>>,
      fn(acc, c) {
        let index =
          crockford_with_index
          |> list.key_find(c)
          |> result.unwrap(0)

        <<acc:bit_string, index:5>>
      },
    )

  let padding =
    bits
    |> bit_size()
    |> int.modulo(8)
    |> result.unwrap(0)

  case bits {
    <<0:size(padding), res:bit_string>> -> Ok(res)
    _other -> Error(Nil)
  }
}
