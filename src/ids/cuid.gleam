import gleam/dynamic
import gleam/int
import gleam/list
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

const base: Int = 36

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

external type CharList

external fn os_getpid() -> CharList =
  "os" "getpid"

external fn char_list_to_string(CharList) -> String =
  "erlang" "list_to_binary"

external fn string_to_char_list(String) -> CharList =
  "erlang" "binary_to_list"

external fn net_adm_localhost() -> List(Int) =
  "net_adm" "localhost"

fn fingerprint() -> String {
  let operator = base * base
  let Ok(pid) =
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
  |> int.to_base_string(base)
}

external fn rand_uniform(Int) -> Int =
  "rand" "uniform"

fn random_block() -> String {
  rand_uniform(discrete_values - 1)
  |> int.to_base_string(base)
  |> string.pad_left(to: block_size, with: "0")
}
