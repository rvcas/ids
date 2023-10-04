//// A module for generating ULIDs (Universally Unique Lexicographically Sortable Identifier).

import gleam/string
import gleam/int
import gleam/result
import gleam/list
import gleam/bit_string

const crockford_alphabet = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"

/// Encode a string using crockfords base32 encoding
pub fn encode_base32(binary: String) -> String {
  let bytes = bit_string.from_string(binary)

  // calculate out how many bits to pad to make the bit_string divisible by 5
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
