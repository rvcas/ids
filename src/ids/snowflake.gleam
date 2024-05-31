//// A module for generating Snowflake IDs.

import gleam/erlang
import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/otp/actor.{type Next}
import gleam/result
import gleam/string

@external(erlang, "binary", "encode_unsigned")
fn encode_unsigned(i: Int) -> BitArray

/// The messages handled by the actor.
/// The actor shouldn't be called directly so this type is opaque.
pub opaque type Message {
  Generate(reply_with: Subject(Int))
}

/// The internal state of the actor.
/// The state keeps track of the Snowflake parts.
pub opaque type State {
  State(epoch: Int, last_time: Int, machine_id: Int, idx: Int)
}

/// Starts a Snowflake generator.
pub fn start(machine_id: Int) -> Result(Subject(Message), String) {
  start_with_epoch(machine_id, 0)
}

/// Starts a Snowflake generator with an epoch offset.
pub fn start_with_epoch(
  machine_id: Int,
  epoch: Int,
) -> Result(Subject(Message), String) {
  case epoch > erlang.system_time(erlang.Millisecond) {
    True -> Error("Error: Epoch can't be larger than current time.")
    False ->
      State(epoch: epoch, last_time: 0, machine_id: machine_id, idx: 0)
      |> actor.start(handle_msg)
      |> result.map_error(fn(err) {
        "Error: Couldn't start actor. Reason: " <> string.inspect(err)
      })
  }
}

/// Generates a Snowflake ID using the given channel.
///
/// ### Usage
/// ```gleam
/// import ids/snowflake
///
/// let assert Ok(channel) = snowflake.start(machine_id: 1)
/// let id: Int = snowflake.generate(channel)
/// 
/// let discord_epoch = 1_420_070_400_000 
/// let assert Ok(d_channel) = snowflake.start_with_epoch(machine_id: 1, epoch: discord_epoch)
/// let discord_id: Int = snowflake.generate(d_channel)
/// ```
pub fn generate(channel: Subject(Message)) -> Int {
  actor.call(channel, Generate, 1000)
}

/// Decodes a Snowflake ID into #(timestamp, machine_id, idx).
pub fn decode(snowflake: Int) -> Result(#(Int, Int, Int), String) {
  case encode_unsigned(snowflake) {
    <<timestamp:int-size(42), machine_id:int-size(10), idx:int-size(12)>> ->
      Ok(#(timestamp, machine_id, idx))
    _other -> Error("Error: Couldn't decode snowflake id.")
  }
}

/// Actor message handler.
fn handle_msg(msg: Message, state: State) -> Next(Message, State) {
  case msg {
    Generate(reply) -> {
      let new_state = update_state(state)

      let snowflake =
        new_state.last_time
        |> int.bitwise_shift_left(22)
        |> int.bitwise_or({
          new_state.machine_id
          |> int.bitwise_shift_left(12)
          |> int.bitwise_or(new_state.idx)
        })

      actor.send(reply, snowflake)
      actor.continue(new_state)
    }
  }
}

/// Prepares the state for generation.
/// Handles incrementing if id is being generated in the same millisecond.
/// Calls itself recursively to make a millisecond pass if all 4096 ids have been generated in the past millisecond.
fn update_state(state: State) -> State {
  let now =
    erlang.system_time(erlang.Millisecond)
    |> int.subtract(state.epoch)

  case state {
    State(last_time: lt, idx: idx, ..) if lt == now && idx < 4095 -> {
      State(..state, idx: state.idx + 1)
    }
    State(last_time: lt, ..) if lt == now -> update_state(state)
    _other -> State(..state, last_time: now, idx: 0)
  }
}
