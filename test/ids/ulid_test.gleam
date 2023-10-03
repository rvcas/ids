import ids/ulid

pub fn gen_test() {
  let assert "64V3JDHK6GV3CD9S68RKE" = ulid.encode_base32("1696346659217")
  let assert "EHJQ6X0" = ulid.encode_base32("test")
}
