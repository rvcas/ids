//// A module for generating NanoIDs, i.e., tiny, secure, URL-friendly, 
//// and unique string IDs.
////

import gleam/bit_array
import gleam/float
import gleam/int
import gleam/list
import gleam/string

/// The default alphabet used when generating NanoIDs.
pub const default_alphabet: BitArray = <<
  "_-0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ":utf8,
>>

/// The default size of the generated NanoIDs. 
pub const default_size: Int = 21

@external(erlang, "crypto", "strong_rand_bytes")
fn crypto_strong_rand_bytes(length: Int) -> BitArray

@external(erlang, "erlang", "bsl")
fn shift_left(n: Int, s: Int) -> Int

@external(erlang, "erlang", "band")
fn and(left: Int, right: Int) -> Int

@external(erlang, "binary", "bin_to_list")
fn bin_to_list(b: BitArray) -> List(Int)

@external(erlang, "math", "log")
fn log(f: Float) -> Float

/// Generates a (random) NanoID. The NanoID produced by this function is 
/// generated using a cryptographically secure random number generator.
///
/// ### Usage
/// ```gleam
/// import ids/nanoid
///
/// let assert Ok(id) = nanoid.generate()
/// ```
///
pub fn generate() -> String {
  // TODO: When optional arguments with defaults becomes a thing in Gleam
  //       make it possble to pass an 'alphabet' and 'size'. For now just
  //       use hardcoded defaults...
  let alphabet: BitArray = default_alphabet

  let assert Ok(alphabet_string) = bit_array.to_string(alphabet)

  let alphabet_length: Int = string.length(alphabet_string)

  let size: Int = default_size

  let assert Ok(Nil) = check_nanoid_args(size, alphabet)

  let mask = calculate_mask(alphabet_length)

  let step = calculate_step(mask, size, alphabet_length)

  let assert Ok(bitstr_nanoid) =
    do_generate(size, alphabet, mask, step, <<"":utf8>>)

  let assert Ok(str_nanoid) = bit_array.to_string(bitstr_nanoid)

  str_nanoid
}

// Recursively generate a NanoID as long as the given size 
// of the ID has not yet been reached
fn do_generate(
  size: Int,
  alphabet: BitArray,
  mask: Int,
  step: Int,
  acc: BitArray,
) -> Result(BitArray, String) {
  case bit_array.byte_size(acc) >= size {
    // Truncate the generated ID to the desired size
    True -> {
      let assert Ok(nanoid) = bit_array.slice(acc, 0, size)
      nanoid
      |> Ok
    }
    // The NanoID is not yet the desired size, so continue 
    // building up the ID
    False ->
      case generate_nanoid(step, alphabet, mask) {
        Ok(partial_nanoid) ->
          bit_array.concat([acc, partial_nanoid])
          |> do_generate(size, alphabet, mask, step, _)
        Error(error) ->
          error
          |> Error
      }
  }
}

fn generate_nanoid(
  size: Int,
  alphabet: BitArray,
  mask: Int,
) -> Result(BitArray, String) {
  case check_nanoid_args(size, alphabet) {
    Ok(Nil) ->
      size
      |> random_bytes()
      |> list.map(fn(x: Int) -> BitArray {
        case bit_array.slice(alphabet, and(x, mask), 1) {
          Ok(nanoid) -> nanoid
          _ -> <<"":utf8>>
        }
      })
      |> bit_array.concat()
      |> Ok
    Error(error) ->
      error
      |> Error
  }
}

fn check_nanoid_args(size: Int, alphabet: BitArray) -> Result(Nil, String) {
  case check_size(size) {
    Ok(Nil) -> check_alphabet(alphabet)
    Error(error) -> Error(error)
  }
}

fn check_size(size: Int) -> Result(Nil, String) {
  case size > 0 {
    True -> Ok(Nil)
    False ->
      Error(
        "Error: The specified ID size is too small. Increase the size of the ID.",
      )
  }
}

fn check_alphabet(alphabet: BitArray) -> Result(Nil, String) {
  case bit_array.byte_size(alphabet) > 1 {
    True -> Ok(Nil)
    False ->
      Error(
        "Error: The specified alphabet size is too small. Increase the size of the alphabet.",
      )
  }
}

// Internal function for generating a list of cryptographically
// secure random bytes (represented by a list of ints)
fn random_bytes(size: Int) -> List(Int) {
  crypto_strong_rand_bytes(size)
  |> bin_to_list()
}

// Calculate a bitmask value that can be used to transform byte vaules 
// into values that are closer to the size of the alphabet used. The 
// bitmask value will be the closest `2^31 - 1` number, that exceeds 
// the alphabet size. For example, the bitmask of the alphabet of size 
// 30 is 31 (00011111)
fn calculate_mask(alphabet_length: Int) -> Int {
  let v1 = log(int.to_float(alphabet_length - 1)) /. log(2.0)
  let v2 = float.round(float.floor(v1))
  shift_left(2, v2) - 1
}

// Calculate a step value that determines how many random bytes to 
// generate. The number of random bytes is decided based on the ID 
// 'size', 'bitmask' value, 'alphabet' size, and a number 1.6 
// (using 1.6 gives the best performance according to benchmarks).
fn calculate_step(mask: Int, size: Int, alphabet_length: Int) -> Int {
  let step: Float =
    float.ceiling(
      1.6
      *. int.to_float(mask)
      *. int.to_float(size)
      /. int.to_float(alphabet_length),
    )
  float.round(step)
}
