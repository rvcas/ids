import gleeunit
import ids/nanoid
import gleeunit/should
import gleam/list
import gleam/string
import gleam/bit_string
import gleam/set.{Set}

pub fn main() {
  gleeunit.main()
}

// Set the number of NanoIDs to generate and validate
const n: Int = 10_000

pub fn nanoid_test() {
  let gen_nanoids =
    list.repeat(<<"":utf8>>, n)
    |> list.try_map(fn(_v: BitString) -> Result(BitString, String) {
      nanoid.generate()
    })

  // Make sure the NanoIDs can be successfully generated
  gen_nanoids
  |> should.be_ok()

  // Access list of successfully generated NanoIDs
  assert Ok(nanoids) = gen_nanoids

  // Make sure the generated IDs are non-empty bit strings
  nanoids
  |> list.all(fn(v: BitString) -> Bool {
    case bit_string.byte_size(v) > 0 {
      True -> True
      False -> False
    }
  })
  |> should.be_true()

  // Make sure the generated IDs have the right size
  nanoids
  |> list.all(fn(v: BitString) -> Bool {
    assert Ok(string) = bit_string.to_string(v)
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
  |> list.all(fn(v: BitString) -> Bool {
    assert Ok(nanoid_string) = bit_string.to_string(v)
    assert Ok(alphabet) = bit_string.to_string(nanoid.default_alphabet)
    nanoid_string
    |> string.to_graphemes()
    |> list.all(fn(w: String) -> Bool { string.contains(alphabet, w) })
  })
  |> should.be_true()

  // Make sure the generated IDs are unique i.e., there are no collisions
  nanoids
  |> set.from_list()
  |> fn(v: Set(BitString)) -> Bool { set.size(v) == list.length(nanoids) }
  |> should.be_true()
}
