import ids/cuid
import gleam/io
import gleam/order
import gleam/should
import gleam/string

pub fn gen_test() {
  assert Ok(channel) = cuid.start()

  let id = cuid.gen(channel)
  let id2 = cuid.gen(channel)

  id
  |> string.starts_with("c")
  |> should.be_true()

  id2
  |> string.starts_with("c")
  |> should.be_true()

  id
  |> string.compare(id2)
  |> should.not_equal(order.Eq)
}
