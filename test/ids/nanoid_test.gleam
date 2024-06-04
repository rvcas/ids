import gleam/bit_array
import gleam/list
import gleam/set.{type Set}
import gleam/string
import gleeunit
import gleeunit/should
import ids/nanoid

pub fn main() {
  gleeunit.main()
}

// Set the number of NanoIDs to generate and validate
const n: Int = 10_000

pub fn nanoid_test() {
  let nanoids: List(String) =
    list.repeat("", n)
    |> list.map(fn(_v: String) -> String { nanoid.generate() })

  // Make sure the generated IDs are non-empty bit strings
  nanoids
  |> list.all(fn(v: String) -> Bool {
    let bitstr_v: BitArray = bit_array.from_string(v)
    case bit_array.byte_size(bitstr_v) > 0 {
      True -> True
      False -> False
    }
  })
  |> should.be_true()

  // Make sure the generated IDs have the right size
  nanoids
  |> list.all(fn(v: String) -> Bool {
    let bitstr_v: BitArray = bit_array.from_string(v)
    let assert Ok(string) = bit_array.to_string(bitstr_v)
    let length: Int =
      string
      |> string.length()
    case length == nanoid.default_size {
      True -> True
      False -> False
    }
  })
  |> should.be_true()

  // Make sure the generated IDs contain the right symbols
  nanoids
  |> list.all(fn(v: String) -> Bool {
    let assert Ok(alphabet) = bit_array.to_string(nanoid.default_alphabet)
    v
    |> string.to_graphemes()
    |> list.all(fn(w: String) -> Bool { string.contains(alphabet, w) })
  })
  |> should.be_true()

  // Make sure the generated IDs are unique i.e., there are no collisions
  nanoids
  |> set.from_list()
  |> fn(v: Set(String)) -> Bool { set.size(v) == list.length(nanoids) }
  |> should.be_true()
}
