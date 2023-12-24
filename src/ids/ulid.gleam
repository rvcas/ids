//// A module for generating ULIDs (Universally Unique Lexicographically Sortable Identifier).

import gleam/string
import gleam/int
import gleam/result
import gleam/list
import gleam/erlang
import gleam/otp/actor.{type Next, type StartResult}
import gleam/erlang/process.{type Subject}

pub const crockford_alphabet = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"

pub const max_time = 281_474_976_710_655

@external(erlang, "crypto", "strong_rand_bytes")
fn crypto_strong_rand_bytes(n: Int) -> BitArray

@external(erlang, "erlang", "bit_size")
fn bit_size(b: BitArray) -> Int

@external(erlang, "binary", "decode_unsigned")
fn decode_unsigned(b: BitArray) -> Int

@external(erlang, "binary", "encode_unsigned")
fn encode_unsigned(i: Int) -> BitArray

/// The messages handled by the actor.
/// The actor shouldn't be called directly so this type is opaque.
pub opaque type Message {
  Generate(reply_with: Subject(Result(String, String)))
  GenerateFromTimestamp(
    timestamp: Int,
    reply_with: Subject(Result(String, String)),
  )
}

/// The internal state of the actor.
/// The state keeps track of the last ULID components to make sure to handle the monotonicity correctly.
pub opaque type State {
  State(last_time: Int, last_random: BitArray)
}

/// Starts a ULID generator.
pub fn start() -> StartResult(Message) {
  actor.start(State(0, <<>>), handle_msg)
}

/// Generates an ULID using the given channel with a monotonicity check.
/// This guarantees sortability if multiple ULID get created in the same millisecond.
///
/// ### Usage
/// ```gleam
/// import ids/ulid
///
/// let assert Ok(channel) = ulid.start()
/// let Ok(id) = ulid.monotonic_generate(channel)
/// ```
pub fn monotonic_generate(channel: Subject(Message)) -> Result(String, String) {
  actor.call(channel, Generate, 1000)
}

/// Generates an ULID from a timestamp using the given channel with a monotonicity check.
/// This guarantees sortability if the same timestamp is used repeatedly back to back.
///
/// ### Usage
/// ```gleam
/// import ids/ulid
///
/// let assert Ok(channel) = ulid.start()
/// let Ok(id) = ulid.monotonic_from_timestamp(channel, 1_696_346_659_217)
/// ```
pub fn monotonic_from_timestamp(
  channel: Subject(Message),
  timestamp: Int,
) -> Result(String, String) {
  actor.call(
    channel,
    fn(subject) { GenerateFromTimestamp(timestamp, subject) },
    1000,
  )
}

/// Generates an ULID.
pub fn generate() -> String {
  let timestamp = erlang.system_time(erlang.Millisecond)

  case from_timestamp(timestamp) {
    Ok(ulid) -> ulid
    _error -> panic as "Error: Couldn't generate ULID."
  }
}

/// Generates an ULID with the supplied unix timestamp in milliseconds.
pub fn from_timestamp(timestamp: Int) -> Result(String, String) {
  from_parts(timestamp, crypto_strong_rand_bytes(10))
}

/// Generates an ULID with the supplied timestamp and randomness.
pub fn from_parts(
  timestamp: Int,
  randomness: BitArray,
) -> Result(String, String) {
  case #(timestamp, randomness) {
    #(time, <<rand:bits-size(80)>>) if time <= max_time ->
      <<timestamp:size(48), rand:bits>>
      |> encode_base32()
      |> Ok
    _other -> {
      let error =
        string.concat([
          "Error: The timestamp is too large or randomness isn't 80 bits. Please use an Unix timestamp smaller than ",
          int.to_string(max_time),
          ".",
        ])
      Error(error)
    }
  }
}

/// Decodes an ULID into #(timestamp, randomness).
pub fn decode(ulid: String) -> Result(#(Int, BitArray), String) {
  case decode_base32(ulid) {
    Ok(<<timestamp:unsigned-size(48), randomness:bits-size(80)>>) ->
      Ok(#(timestamp, randomness))
    _other -> Error("Error: Decoding failed. Is a valid ULID being supplied?")
  }
}

/// Encode a bit_string using crockfords base32 encoding.
fn encode_base32(bytes: BitArray) -> String {
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

  encode_bytes(<<0:size(to_pad), bytes:bits>>)
}

/// Recursively grabs 5 bits and uses them as index in the crockford alphabet and concatenates them to a string.
fn encode_bytes(binary: BitArray) -> String {
  case binary {
    <<index:unsigned-size(5), rest:bits>> -> {
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
fn decode_base32(binary: String) -> Result(BitArray, Nil) {
  let crockford_with_index =
    crockford_alphabet
    |> string.to_graphemes()
    |> list.index_map(fn(i, x) { #(i, x) })

  let bits =
    binary
    |> string.to_graphemes()
    |> list.fold(<<>>, fn(acc, c) {
      let index =
        crockford_with_index
        |> list.key_find(c)
        |> result.unwrap(0)

      <<acc:bits, index:5>>
    })

  let padding =
    bits
    |> bit_size()
    |> int.modulo(8)
    |> result.unwrap(0)

  case bits {
    <<0:size(padding), res:bits>> -> Ok(res)
    _other -> Error(Nil)
  }
}

/// Actor message handler.
fn handle_msg(msg: Message, state: State) -> Next(Message, State) {
  case msg {
    Generate(reply) -> {
      erlang.system_time(erlang.Millisecond)
      |> generate_response_ulid(reply, state)
    }

    GenerateFromTimestamp(timestamp, reply) ->
      timestamp
      |> generate_response_ulid(reply, state)
  }
}

/// Response message helper.
fn generate_response_ulid(
  timestamp: Int,
  reply: Subject(Result(String, String)),
  state: State,
) -> Next(Message, State) {
  case state.last_time == timestamp {
    True -> {
      let randomness =
        state.last_random
        |> decode_unsigned()
        |> int.add(1)
        |> encode_unsigned()

      case from_parts(timestamp, randomness) {
        Ok(ulid) -> actor.send(reply, Ok(ulid))
        _error -> actor.send(reply, Error("Error: Couldn't generate ULID."))
      }

      actor.continue(State(last_time: timestamp, last_random: randomness))
    }

    False -> {
      let randomness = crypto_strong_rand_bytes(10)

      case from_parts(timestamp, randomness) {
        Ok(ulid) -> actor.send(reply, Ok(ulid))
        _error -> actor.send(reply, Error("Error: Couldn't generate ULID."))
      }

      actor.continue(State(last_time: timestamp, last_random: randomness))
    }
  }
}
