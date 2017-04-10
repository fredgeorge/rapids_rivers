require 'test_helper'

# Ensures Packet operates correctly
class PacketTest < MiniTest::Test

  JSON_HASH = JSON.parse(
      "{\"need\":\"car_rental_offer\"," +
        "\"user_id\":456," +
        "\"solutions\":[" +
        "{\"offer\":\"15% discount\"}," +
        "{\"offer\":\"500 extra points\"}," +
        "{\"offer\":\"free upgrade\"}" +
        "]," +
        "\"membership_level\":\"\"," +
        "\"system_read_count\":2," +
        "\"contributing_services\":[]}");

  def test_pretty_print
    expected =
"{
  \"need\": \"car_rental_offer\",
  \"user_id\": 456,
  \"solutions\": [
    {
      \"offer\": \"15% discount\"
    },
    {
      \"offer\": \"500 extra points\"
    },
    {
      \"offer\": \"free upgrade\"
    }
  ],
  \"membership_level\": \"\",
  \"system_read_count\": 3,
  \"contributing_services\": [

  ]
}"
    assert_equal(expected, RapidsRivers::Packet.new(JSON_HASH).pretty_print)
  end

end
