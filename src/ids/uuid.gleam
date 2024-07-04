//// A module for generating UUIDs (Universally Unique Identifiers).
////
//// The module currently supports UUID versions:
//// - Version 4 (random)
//// - Version 7 (with unix timestamp)
////

import gleam/bit_array
import gleam/erlang
import gleam/result

@external(erlang, "crypto", "strong_rand_bytes")
fn crypto_strong_rand_bytes(n: Int) -> BitArray

/// Generates a version 4 (random) UUID. The version 4 UUID produced
/// by this function is generated using a cryptographically secure 
/// random number generator.
///
/// ### Usage
/// ```gleam
/// import ids/uuid
///
/// let assert Ok(id) = uuid.generate_v4()
/// ```
///
pub fn generate_v4() -> Result(String, String) {
  let assert <<u0:size(48), _:size(4), u1:size(12), _:size(2), u2:size(62)>> =
    crypto_strong_rand_bytes(16)

  cast(<<u0:size(48), 4:size(4), u1:size(12), 2:size(2), u2:size(62)>>)
}

/// Generates a version 7 UUID. The version 7 UUID produced
/// by this function is generated using a cryptographically secure 
/// random number generator and includes a unix timestamp.
///
/// ### Usage
/// ```gleam
/// import ids/uuid
///
/// let assert Ok(id) = uuid.generate_v7()
/// ```
///
pub fn generate_v7() -> Result(String, String) {
  let timestamp = erlang.system_time(erlang.Millisecond)
  generate_v7_from_timestamp(timestamp)
}

/// Generates a version 7 UUID from a given unix timestamp in milliseconds.
pub fn generate_v7_from_timestamp(timestamp: Int) -> Result(String, String) {
  let assert <<_:size(48), _:size(4), a:size(12), _:size(2), b:size(62)>> =
    crypto_strong_rand_bytes(16)

  cast(<<timestamp:size(48), 7:size(4), a:size(12), 2:size(2), b:size(62)>>)
}

/// Decodes a version 7 UUID to #(timestamp, version, random_a, rfc_variant, random_b).
pub fn decode_v7(
  uuid_v7: String,
) -> Result(#(Int, Int, BitArray, Int, BitArray), String) {
  uuid_v7
  |> bit_array.from_string()
  |> dump()
  |> result.try(fn(d) {
    case d {
      <<
        timestamp:unsigned-size(48),
        ver:unsigned-size(4),
        a:bits-size(12),
        var:unsigned-size(2),
        b:bits-size(62),
      >> -> Ok(#(timestamp, ver, a, var, b))
      _other -> Error("Error: Couldn't match raw UUID v7.")
    }
  })
}

@internal
pub fn cast(raw_uuid: BitArray) -> Result(String, String) {
  case raw_uuid {
    <<
      a1:size(4),
      a2:size(4),
      a3:size(4),
      a4:size(4),
      a5:size(4),
      a6:size(4),
      a7:size(4),
      a8:size(4),
      b1:size(4),
      b2:size(4),
      b3:size(4),
      b4:size(4),
      c1:size(4),
      c2:size(4),
      c3:size(4),
      c4:size(4),
      d1:size(4),
      d2:size(4),
      d3:size(4),
      d4:size(4),
      e1:size(4),
      e2:size(4),
      e3:size(4),
      e4:size(4),
      e5:size(4),
      e6:size(4),
      e7:size(4),
      e8:size(4),
      e9:size(4),
      e10:size(4),
      e11:size(4),
      e12:size(4),
    >> ->
      <<
        e(a1),
        e(a2),
        e(a3),
        e(a4),
        e(a5),
        e(a6),
        e(a7),
        e(a8),
        45,
        e(b1),
        e(b2),
        e(b3),
        e(b4),
        45,
        e(c1),
        e(c2),
        e(c3),
        e(c4),
        45,
        e(d1),
        e(d2),
        e(d3),
        e(d4),
        45,
        e(e1),
        e(e2),
        e(e3),
        e(e4),
        e(e5),
        e(e6),
        e(e7),
        e(e8),
        e(e9),
        e(e10),
        e(e11),
        e(e12),
      >>
      |> bit_array.to_string()
      |> result.replace_error(
        "Error: BitString could not be converted to String.",
      )

    _other -> Error("Error: Raw UUID is malformed.")
  }
}

@internal
pub fn dump(uuid: BitArray) -> Result(BitArray, String) {
  case uuid {
    <<
      a1,
      a2,
      a3,
      a4,
      a5,
      a6,
      a7,
      a8,
      45,
      b1,
      b2,
      b3,
      b4,
      45,
      c1,
      c2,
      c3,
      c4,
      45,
      d1,
      d2,
      d3,
      d4,
      45,
      e1,
      e2,
      e3,
      e4,
      e5,
      e6,
      e7,
      e8,
      e9,
      e10,
      e11,
      e12,
    >> ->
      <<
        d(a1):size(4),
        d(a2):size(4),
        d(a3):size(4),
        d(a4):size(4),
        d(a5):size(4),
        d(a6):size(4),
        d(a7):size(4),
        d(a8):size(4),
        d(b1):size(4),
        d(b2):size(4),
        d(b3):size(4),
        d(b4):size(4),
        d(c1):size(4),
        d(c2):size(4),
        d(c3):size(4),
        d(c4):size(4),
        d(d1):size(4),
        d(d2):size(4),
        d(d3):size(4),
        d(d4):size(4),
        d(e1):size(4),
        d(e2):size(4),
        d(e3):size(4),
        d(e4):size(4),
        d(e5):size(4),
        d(e6):size(4),
        d(e7):size(4),
        d(e8):size(4),
        d(e9):size(4),
        d(e10):size(4),
        d(e11):size(4),
        d(e12):size(4),
      >>
      |> Ok()
    _other -> Error("Error: UUID is malformed.")
  }
}

fn e(n: Int) -> Int {
  case n {
    0 -> 48
    1 -> 49
    2 -> 50
    3 -> 51
    4 -> 52
    5 -> 53
    6 -> 54
    7 -> 55
    8 -> 56
    9 -> 57
    10 -> 97
    11 -> 98
    12 -> 99
    13 -> 100
    14 -> 101
    15 -> 102
    _ -> 102
  }
}

fn d(n: Int) -> Int {
  case n {
    48 -> 0
    49 -> 1
    50 -> 2
    51 -> 3
    52 -> 4
    53 -> 5
    54 -> 6
    55 -> 7
    56 -> 8
    57 -> 9
    97 -> 10
    98 -> 11
    99 -> 12
    100 -> 13
    101 -> 14
    102 -> 15
    _ -> 15
  }
}
