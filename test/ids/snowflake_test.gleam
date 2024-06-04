import gleam/erlang
import gleam/int
import gleam/list
import gleam/string
import gleeunit/should
import ids/snowflake

pub fn gen_test() {
  let machine_id = 1
  let assert Ok(channel) = snowflake.start(machine_id)

  let snowflake = snowflake.generate(channel)

  snowflake
  |> int.to_string()
  |> string.length()
  |> should.equal(19)

  let assert Ok(#(timestamp, m_id, idx)) = snowflake.decode(snowflake)

  { timestamp <= erlang.system_time(erlang.Millisecond) }
  |> should.be_true()
  m_id
  |> should.equal(machine_id)
  idx
  |> should.equal(0)

  list.range(1, 5000)
  |> list.map(fn(_) { snowflake.generate(channel) })
  |> list.unique()
  |> list.length()
  |> should.equal(5000)
}

pub fn gen_with_epoch_test() -> Nil {
  let machine_id = 1
  let now = erlang.system_time(erlang.Millisecond)

  let now_much = erlang.system_time(erlang.Millisecond) + 1000
  snowflake.start_with_epoch(machine_id, now_much)
  |> should.be_error()

  let discord_epoch = 1_420_070_400_000
  let assert Ok(channel) = snowflake.start_with_epoch(machine_id, discord_epoch)

  let discord_snowflake = snowflake.generate(channel)

  discord_snowflake
  |> int.to_string()
  |> string.length()
  |> should.equal(19)

  let assert Ok(#(timestamp, _, _)) = snowflake.decode(discord_snowflake)

  let t = timestamp + discord_epoch
  { t >= now && t <= { now + 1000 } }
  |> should.be_true()
}
