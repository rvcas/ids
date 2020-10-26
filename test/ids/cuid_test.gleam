import ids/cuid
import gleam/int
import gleam/iterator.{Done, Next}
import gleam/list
import gleam/map
import gleam/order
import gleam/pair
import gleam/should

const start: Int = 0

const max: Int = 100_000

pub fn gen_test() {
  assert Ok(channel) = cuid.start()

  start
  |> iterator.unfold(with: fn(acc) {
    case acc < max {
      False -> Done
      True -> Next(element: cuid.gen(channel), accumulator: acc + 1)
    }
  })
  |> iterator.fold(
    from: tuple(map.new(), True),
    with: fn(id, acc) {
      let tuple(id_map, flag) = acc

      case flag {
        False -> acc
        True ->
          case map.get(id_map, id) {
            Ok(_) -> tuple(id_map, False)
            Error(_) -> tuple(map.insert(id_map, id, id), True)
          }
      }
    },
  )
  |> pair.second()
  |> should.be_true()
}
