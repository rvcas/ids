//// Module for generating TypeIDs.

import gleam/bit_array
import gleam/regex
import gleam/result
import gleam/string
import ids/utils
import ids/uuid

@internal
pub const alphabet = "0123456789abcdefghjkmnpqrstvwxyz"

/// Generate a TypeID using the supplied prefix. Prefix may be an empty string.
///
/// ### Usage
/// ```gleam
/// generate("user") // Ok("user_01hz7jxhgpfxh9m33bn41tcg9t")
/// generate("") // Ok("01hz7jv26zfnx9gpb0hvyc4pss")
/// ```
pub fn generate(prefix prefix: String) -> Result(String, String) {
  use uuid <- result.try(uuid.generate_v7())
  from_uuid(prefix: prefix, uuid: uuid)
}

/// Generate a TypeID using the supplied prefix and UUID. Prefix may be an empty string.
///
/// ### Usage
/// ```gleam
/// from_uuid("user", "018fcec0-b44b-7ce2-b187-2f08349beab9") // Ok("user_01hz7c1d2bfkhb31sf10t9qtns")
/// ```
pub fn from_uuid(
  prefix prefix: String,
  uuid uuid: String,
) -> Result(String, String) {
  let assert Ok(re) = regex.from_string("^([a-z]([a-z_]{0,61}[a-z])?)?$")

  case regex.check(re, prefix) {
    True -> {
      let p = case prefix {
        "" -> ""
        _ -> prefix <> "_"
      }

      use raw_uuid <- result.try(
        uuid
        |> bit_array.from_string
        |> uuid.dump,
      )

      let id = utils.encode_base32(raw_uuid, alphabet)

      Ok(p <> id)
    }
    False ->
      Error(
        "Error: Prefix must contain at most 63 characters and only lowercase alphabetic ASCII characters [a-z], or an underscore.",
      )
  }
}

/// Decode a TypeID into a tuple of #(prefix, uuid)
///
/// ### Usage
/// ```gleam
/// decode("user_01hz7c1d2bfkhb31sf10t9qtns") // Ok(#("user", "018fcec0-b44b-7ce2-b187-2f08349beab9"))
/// ```
pub fn decode(tid) -> Result(#(String, String), String) {
  case tid |> string.reverse |> string.split_once(on: "_") {
    Ok(#(xiffus, xiferp)) -> {
      use uuid <- result.try(
        xiffus
        |> string.reverse
        |> decode_suffix,
      )
      Ok(#(string.reverse(xiferp), uuid))
    }
    Error(Nil) -> {
      use uuid <- result.try(decode_suffix(tid))
      Ok(#("", uuid))
    }
  }
}

fn decode_suffix(suffix) -> Result(String, String) {
  use raw_uuid <- result.try(
    suffix
    |> utils.decode_base32(alphabet)
    |> result.replace_error("Error: Couldn't decode suffix."),
  )

  use uuid <- result.try(
    raw_uuid
    |> uuid.cast
    |> result.replace_error("Error: Couldn't decode UUID."),
  )

  Ok(uuid)
}
