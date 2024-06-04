import gleam/dict
import gleam/iterator.{Done, Next}
import gleam/pair
import gleam/string
import gleeunit/should
import ids/cuid

pub fn gen_test() {
  let assert Ok(channel) = cuid.start()

  fn() { cuid.generate(channel) }
  |> check_collision()
  |> should.be_true()

  cuid.generate(channel)
  |> string.starts_with("c")
  |> should.be_true()
}

pub fn is_cuid_test() {
  "random"
  |> cuid.is_cuid()
  |> should.be_false()

  "ckgr2o7lm0000ygenmx3pnnuf"
  |> cuid.is_cuid()
  |> should.be_true()
}

pub fn slug_test() {
  let assert Ok(channel) = cuid.start()

  fn() { cuid.slug(channel) }
  |> check_collision()
  |> should.be_true()

  cuid.slug(channel)
  |> cuid.is_slug()
  |> should.be_true()
}

pub fn is_slug_test() {
  "random"
  |> cuid.is_slug()
  |> should.be_false()

  "12345678"
  |> cuid.is_slug()
  |> should.be_true()
}

const start: Int = 0

const max: Int = 100_000

fn check_collision(func: fn() -> String) -> Bool {
  start
  |> iterator.unfold(with: fn(acc) {
    case acc < max {
      False -> Done
      True -> Next(element: func(), accumulator: acc + 1)
    }
  })
  |> iterator.fold(from: #(dict.new(), True), with: fn(acc, id) {
    let #(id_dict, flag) = acc

    case flag {
      False -> acc
      True ->
        case dict.get(id_dict, id) {
          Ok(_) -> #(id_dict, False)
          Error(_) -> #(dict.insert(id_dict, id, id), True)
        }
    }
  })
  |> pair.second()
}
