import ids/cuid
import gleam/int
import gleam/iterator.{Done, Next}
import gleam/list
import gleam/map
import gleam/order
import gleam/should

const max: Int = 200_000

pub fn gen_test() {
  assert Ok(channel) = cuid.start()

  let ids =
    map.new()
    |> iterator.unfold(with: fn(id_map) {
      let id = cuid.gen(channel)

      case map.get(id_map, id) {
        Ok(_) -> Done
        Error(_) -> Next(element: Nil, accumulator: map.insert(id_map, id, id))
      }
    })
    |> iterator.take(max)

  list.length(ids)
  |> int.compare(max)
  |> should.equal(order.Eq)
}
