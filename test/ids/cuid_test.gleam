import ids/cuid
import gleam/int
import gleam/iterator.{Next}
import gleam/list
import gleam/order
import gleam/should

pub fn gen_test() {
  assert Ok(channel) = cuid.start()

  let ids =
    Nil
    |> iterator.unfold(with: fn(acc) {
      Next(element: cuid.gen(channel), accumulator: acc)
    })
    |> iterator.take(2_000)

  let unique_ids = list.unique(ids)

  list.length(ids)
  |> int.compare(list.length(unique_ids))
  |> should.equal(order.Eq)
}
