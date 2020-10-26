import gleam/dynamic
import gleam/int
import gleam/list
import gleam/os.{Millisecond}
import gleam/otp/actor.{Continue, StartResult}
import gleam/otp/process.{Sender}
import gleam/otp/system
import gleam/string

pub opaque type Message {
  Generate(Sender(String))
}

pub opaque type State {
  State(count: Int, fingerprint: String)
}

pub fn start() -> StartResult(Message) {
  actor.start(State(0, get_fingerprint()), handle_msg)
}

pub fn gen(channel: Sender(Message)) -> String {
  actor.call(channel, Generate, 1000)
}

fn handle_msg(msg: Message, state: State) {
  case msg {
    Generate(reply) -> {
      let id =
        [
          "c",
          timestamp(),
          format_count(state.count),
          state.fingerprint,
          random_block(),
          random_block(),
        ]
        |> string.concat()
        |> string.lowercase()
      actor.send(reply, id)
      Continue(State(..state, count: state.count + 1))
    }
  }
}

const base: Int = 36

const block_size: Int = 4

const discrete_values: Int = 1_679_616

fn timestamp() -> String {
  let secs = os.system_time(Millisecond)

  secs
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

external fn net_adm_localhost() -> List(Int) =
  "net_adm" "localhost"

fn get_fingerprint() -> String {
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
