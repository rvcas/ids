//// A module for generating ULIDs (Universally Unique Lexicographically Sortable Identifier).

import gleam/string
import gleam/int
import gleam/io
import gleam/result
import gleam/list
import gleam/bit_string

const crockford_alphabet = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"

pub fn encode_base32(binary: String) -> String {
  let bytes = bit_string.from_string(binary)
  io.debug(bit_string.byte_size(bytes))
  let to_pad =
    { { { bit_string.byte_size(bytes) / 5 } + 1 } * 5 } - bit_string.byte_size(
      bytes,
    )
  io.debug(to_pad)

  bytes
  |> fn(bits) { <<bits:bit_string, 0:size(to_pad)>> }
  |> io.debug()
  |> encode_bytes()
}

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
