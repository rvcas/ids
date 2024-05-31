//// Module for shared functionality.

import gleam/list
import gleam/result
import gleam/string

/// Encode a 128 bit BitArray with base32 encoding using the supplied alphabet.
/// Used by ULID and TypeID
@internal
pub fn encode_base32(bytes: BitArray, alphabet: String) -> String {
  // pad 2 bits because we only supply 128 bits of data but need 130 bits for encoding
  encode_bytes(<<0:size(2), bytes:bits>>, alphabet)
}

/// Recursively grabs 5 bits and uses them as index in the alphabet and concatinates them to a string.
fn encode_bytes(binary: BitArray, alphabet: String) -> String {
  case binary {
    <<index:unsigned-size(5), rest:bits>> -> {
      alphabet
      |> string.to_graphemes
      |> list.at(index)
      |> result.unwrap("0")
      |> string.append(encode_bytes(rest, alphabet))
    }
    _ -> ""
  }
}

/// Decode a string with the supplied alphabet and base32 encoding.
/// Used by ULID and TypeID
@internal
pub fn decode_base32(binary: String, alphabet: String) -> Result(BitArray, Nil) {
  let alphabet_with_index =
    alphabet
    |> string.to_graphemes
    |> list.index_map(fn(x, i) { #(x, i) })

  let bits =
    binary
    |> string.to_graphemes
    |> list.fold(<<>>, fn(acc, c) {
      let index =
        alphabet_with_index
        |> list.key_find(c)
        |> result.unwrap(0)

      <<acc:bits, index:5>>
    })

  case bits {
    <<0:size(2), res:bits>> -> Ok(res)
    _other -> Error(Nil)
  }
}
