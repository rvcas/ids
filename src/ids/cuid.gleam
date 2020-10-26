import gleam/int
import gleam/dynamic
import gleam/os.{Microsecond}
import gleam/otp/actor.{Continue, StartResult}
import gleam/otp/process.{Sender}
import gleam/otp/system
import gleam/string

pub type Message {
  Increment
}

pub fn start() -> StartResult(Message) {
  actor.start(0, handle_msg)
}

pub fn gen(channel: Sender(Message)) -> String {
  let state =
    channel
    |> process.pid()
    |> system.get_state()

  let Ok(count) = dynamic.int(state)

  actor.send(channel, Increment)

  [
    "c",
    timestamp(),
    format_count(count),
    fingerprint(),
    random_block(),
    random_block(),
  ]
  |> string.concat()
  |> string.lowercase()
}

fn handle_msg(msg: Message, state: Int) {
  case msg {
    Increment -> Continue(state + 1)
  }
}

const base: Int = 35

const block_size: Int = 4

const discrete_values: Int = 1_679_616

fn timestamp() -> String {
  let secs = os.system_time(Microsecond)

  secs % discrete_values * discrete_values
  |> int.to_base_string(base)
}

fn format_count(num: Int) {
  num
  |> int.to_base_string(base)
  |> string.pad_left(to: block_size, with: "0")
}

fn fingerprint() -> String {
  ""
}

fn random_block() -> String {
  ""
}
