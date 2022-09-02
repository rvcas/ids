//// A module for generating CUIDs (Collision-resistant Unique Identifiers).
//// The implementation requires a counter, so an actor is used to keep track
//// of that state. This means before generating a CUID, an actor needs to be
//// started and all work is done via a channel.
////
//// Slugs are also supported.
////

import gleam/int
import gleam/list
import gleam/erlang.{Millisecond}
import gleam/otp/actor.{Continue, Next, StartResult}
import gleam/erlang/process.{Subject}
import gleam/string

/// The messages handled by the actor.
///
/// The actor shouldn't be called directly so this type is opaque.
pub opaque type Message {
  Generate(Subject(String))
  GenerateSlug(Subject(String))
}

/// The internal state of the actor.
///
/// The state keeps track of a counter and a fingerprint.
/// Both are used when generating a CUID.
pub opaque type State {
  State(count: Int, fingerprint: String)
}

/// Starts a CUID generator.
pub fn start() -> StartResult(Message) {
  actor.start(State(0, get_fingerprint()), handle_msg)
}

/// Generates a CUID using the given channel.
///
/// ### Usage
/// ```gleam
/// import ids/cuid
///
/// assert Ok(channel) = cuid.start()
///
/// let id: String = cuid.generate(channel)
///
/// let slug: String = cuid.slug(channel)
/// ```
pub fn generate(channel: Subject(Message)) -> String {
  actor.call(channel, Generate, 1000)
}

/// Checks if a string is a CUID.
pub fn is_cuid(id: String) -> Bool {
  string.starts_with(id, "c")
}

/// Generates a slug using the given channel.
pub fn slug(channel: Subject(Message)) -> String {
  actor.call(channel, GenerateSlug, 1000)
}

/// Checks if a string is a slug.
pub fn is_slug(slug: String) -> Bool {
  let slug_length = string.length(slug)

  slug_length >= 7 && slug_length <= 10
}

const base: Int = 36

fn handle_msg(msg: Message, state: State) -> Next(State) {
  case msg {
    Generate(reply) -> {
      let id =
        format_id([
          "c",
          timestamp(),
          format_count(state.count),
          state.fingerprint,
          random_block(),
          random_block(),
        ])
      actor.send(reply, id)
      Continue(State(..state, count: new_count(state.count)))
    }
    GenerateSlug(reply) -> {
      let slug =
        format_id([
          timestamp()
          |> string.slice(-2, 2),
          format_count(state.count)
          |> string.slice(-4, 4),
          string.concat([
            string.slice(state.fingerprint, 0, 1),
            string.slice(state.fingerprint, -1, 1),
          ]),
          random_block()
          |> string.slice(-2, 2),
        ])
      actor.send(reply, slug)
      Continue(State(..state, count: new_count(state.count)))
    }
  }
}

const block_size: Int = 4

const discrete_values: Int = 1_679_616

fn format_id(id_data: List(String)) -> String {
  id_data
  |> string.concat()
  |> string.lowercase()
}

fn new_count(count: Int) -> Int {
  case count < discrete_values {
    True -> count + 1
    False -> 0
  }
}

fn timestamp() -> String {
  let secs = erlang.system_time(Millisecond)

  secs
  |> int.to_base36()
}

fn format_count(num: Int) -> String {
  num
  |> int.to_base36()
  |> string.pad_left(to: block_size, with: "0")
}

external type CharList

external fn os_getpid() -> CharList =
  "os" "getpid"

external fn char_list_to_string(CharList) -> String =
  "erlang" "list_to_binary"

external fn net_adm_localhost() -> List(Int) =
  "net_adm" "localhost"

fn get_fingerprint() -> String {
  let operator = base * base
  assert Ok(pid) =
    os_getpid()
    |> char_list_to_string()
    |> int.parse()

  let id = pid % operator * operator

  let localhost = net_adm_localhost()
  let sum =
    localhost
    |> list.fold(from: 0, with: fn(char, acc) { char + acc })

  let hostid = { sum + list.length(localhost) + base } % operator

  id + hostid
  |> int.to_base36()
}

external fn rand_uniform(Int) -> Int =
  "rand" "uniform"

fn random_block() -> String {
  rand_uniform(discrete_values - 1)
  |> int.to_base36()
  |> string.pad_left(to: block_size, with: "0")
}
