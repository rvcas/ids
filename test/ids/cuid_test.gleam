import ids/cuid
import gleam/int
import gleam/iterator.{Done, Next}
import gleam/list
import gleam/map
import gleam/order
import gleam/pair
import gleam/should
import gleam/string

pub fn gen_test() {
  assert Ok(channel) = cuid.start()

  fn() { cuid.gen(channel) }
  |> check_collision()
  |> should.be_true()

  cuid.gen(channel)
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
  assert Ok(channel) = cuid.start()

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
  |> iterator.fold(
    from: #(map.new(), True),
    with: fn(id, acc) {
      let #(id_map, flag) = acc

      case flag {
        False -> acc
        True ->
          case map.get(id_map, id) {
            Ok(_) -> #(id_map, False)
            Error(_) -> #(map.insert(id_map, id, id), True)
          }
      }
    },
  )
  |> pair.second()
}
