//// A module for generating NanoIDs, i.e., tiny, secure, URL-friendly, 
//// and unique string IDs.
////

import gleam/string
import gleam/bit_string
import gleam/float
import gleam/int
import gleam/list

/// The default alphabet used when generating NanoIDs.
pub const default_alphabet: BitString = <<
  "_-0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ":utf8,
>>

/// The default size of the generated NanoIDs. 
pub const default_size: Int = 21

external fn crypto_strong_rand_bytes(Int) -> BitString =
  "crypto" "strong_rand_bytes"

external fn shift_left(Int, Int) -> Int =
  "erlang" "bsl"

external fn and(Int, Int) -> Int =
  "erlang" "band"

external fn bin_to_list(BitString) -> List(Int) =
  "binary" "bin_to_list"

external fn log(Float) -> Float =
  "math" "log"

fn check_nanoid_args(size: Int, alphabet: BitString) -> Result(Bool, String) {
  case check_size(size) {
    Ok(True) ->
      case check_alphabet(alphabet) {
        Ok(True) ->
          True
          |> Ok
        Error(error) ->
          error
          |> Error
      }
    Error(error) ->
      error
      |> Error
  }
}

fn check_size(size: Int) -> Result(Bool, String) {
  case size > 0 {
    True ->
      True
      |> Ok
    False -> {
      let error: String =
        "Error: The specified ID size is too small. Increase the size of the ID."
      error
      |> Error
    }
  }
}

fn check_alphabet(alphabet: BitString) -> Result(Bool, String) {
  case bit_string.byte_size(alphabet) > 1 {
    True ->
      True
      |> Ok
    False -> {
      let error: String =
        "Error: The specified alphabet size is too small. Increase the size of the alphabet."
      error
      |> Error
    }
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
      1.6 *. int.to_float(mask) *. int.to_float(size) /. int.to_float(
        alphabet_length,
      ),
    )
  float.round(step)
}

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
pub fn generate() -> Result(String, String) {
  // TODO: When optional arguments with defaults becomes a thing in Gleam
  //       make it possble to pass an 'alphabet' and 'size'. For now just
  //       use hardcoded defaults...
  let alphabet: BitString = default_alphabet
  let assert Ok(alphabet_string) = bit_string.to_string(alphabet)
  let alphabet_length: Int = string.length(alphabet_string)
  let size: Int = default_size
  case check_nanoid_args(size, alphabet) {
    Ok(True) -> {
      let mask = calculate_mask(alphabet_length)
      let step = calculate_step(mask, size, alphabet_length)
      case do_generate(size, default_alphabet, mask, step, <<"":utf8>>) {
        Ok(bitstr_nanoid) ->
          case bit_string.to_string(bitstr_nanoid) {
            Ok(str_nanoid) ->
              str_nanoid
              |> Ok
            Error(_) -> {
              let error: String =
                "Error: BitString could not be converted to String."
              error
              |> Error
            }
          }
        Error(error) ->
          error
          |> Error
      }
    }
    Error(error) ->
      error
      |> Error
  }
}

// Recursively generate a NanoID as long as the given size 
// of the ID has not yet been reached
fn do_generate(
  size: Int,
  alphabet: BitString,
  mask: Int,
  step: Int,
  acc: BitString,
) -> Result(BitString, String) {
  case bit_string.byte_size(acc) >= size {
    // Truncate the generated ID to the desired size
    True -> {
      let assert Ok(nanoid) = bit_string.slice(acc, 0, size)
      nanoid
      |> Ok
    }
    // The NanoID is not yet the desired size, so continue 
    // building up the ID
    False ->
      case generate_nanoid(step, alphabet, mask) {
        Ok(partial_nanoid) ->
          bit_string.concat([acc, partial_nanoid])
          |> do_generate(size, alphabet, mask, step, _)
        Error(error) ->
          error
          |> Error
      }
  }
}

fn generate_nanoid(
  size: Int,
  alphabet: BitString,
  mask: Int,
) -> Result(BitString, String) {
  case check_nanoid_args(size, alphabet) {
    Ok(True) ->
      size
      |> random_bytes()
      |> list.map(fn(x: Int) -> BitString {
        case bit_string.slice(alphabet, and(x, mask), 1) {
          Ok(nanoid) -> nanoid
          _ -> <<"":utf8>>
        }
      })
      |> bit_string.concat()
      |> Ok
    Error(error) ->
      error
      |> Error
  }
}
