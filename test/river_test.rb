require 'test_helper'

# Ensures River can properly filter JSON messages per required validations
class RiverTest < MiniTest::Test
  SOLUTION_STRING =
      "{\"need\":\"car_rental_offer\"," +
        "\"user_id\":456," +
        "\"solutions\":[" +
        "{\"offer\":\"15% discount\"}," +
        "{\"offer\":\"500 extra points\"}," +
        "{\"offer\":\"free upgrade\"}" +
        "]," +
        "\"frequent_renter\":\"\"," +
        "\"system_read_count\":2," +
        "\"contributing_services\":[]}";

  def setup
    @rapids_connection = TestRapids.new
    @river = RapidsRivers::River.new(@rapids_connection)
    @service = TestService.new(self)
    @river.register(@service)
  end

  def test_json_valid
    @service.define_singleton_method :packet do |send_port, packet, warnings|
      refute_messages warnings
    end
    @rapids_connection.received_message SOLUTION_STRING
  end

  def test_json_invalid
    @service.define_singleton_method :on_error do |send_port, errors|
      assert_errors errors
    end
    @rapids_connection.received_message "{\"key\":value}"
  end

  def test_required_field
    @river.require 'need', 'user_id'
    @service.define_singleton_method :packet do |send_port, packet, warnings|
      refute_messages warnings
      packet.need = packet.need + "_extra"
      packet.user_id = packet.user_id + 14
      assert_equal 'car_rental_offer_extra', packet.need
      assert_equal 470, packet.user_id
    end
    @rapids_connection.received_message SOLUTION_STRING
  end

  def test_required_field_missing
    @river.require 'need', 'missing_key'
    @service.define_singleton_method :on_error do |send_port, errors|
      assert_errors errors
    end
    @rapids_connection.received_message SOLUTION_STRING
  end

  def test_empty_array_field_implies_missing
    @river.require 'contributing_services'
    @service.define_singleton_method :on_error do |send_port, errors|
      assert_errors errors
    end
    @rapids_connection.received_message SOLUTION_STRING
  end

  def test_empty_string_field_implies_missing
    @river.require 'frequent_renter'
    @service.define_singleton_method :on_error do |send_port, errors|
      assert_errors errors
    end
    @rapids_connection.received_message SOLUTION_STRING
  end

  def test_forbidden_field
    @river.forbid 'frequent_renter', 'contributing_services', 'missing_key'
    @service.define_singleton_method :packet do |send_port, packet, warnings|
      refute_messages warnings
      packet.frequent_renter = 'platinum'
      assert_equal 'platinum', packet.frequent_renter
      packet.contributing_services << 'a testing service'
      packet.missing_key = '<accessor created>'
    end
    @rapids_connection.received_message SOLUTION_STRING
  end

  def test_forbidden_field_exists
    @river.forbid 'frequent_renter', 'user_id'
    @service.define_singleton_method :on_error do |send_port, errors|
      assert_errors errors
    end
    @rapids_connection.received_message SOLUTION_STRING
  end

  def test_required_value_match
    @river.require_values(need: 'car_rental_offer')
    @service.define_singleton_method :packet do |send_port, packet, warnings|
      refute_messages warnings
    end
    @rapids_connection.received_message SOLUTION_STRING
  end

  def test_required_value_incorrect
    @river.require_values(need: 'airline_discount')
    @service.define_singleton_method :on_error do |send_port, errors|
      assert_errors errors
    end
    @rapids_connection.received_message SOLUTION_STRING
  end

  def test_interesting_new_field
    @river.interested_in 'new_key'
    @service.define_singleton_method :packet do |send_port, packet, warnings|
      refute_messages warnings
      packet.new_key = 17
      packet.new_key += 25
      assert_equal 42, packet.new_key
    end
    @rapids_connection.received_message SOLUTION_STRING
  end

  def test_interesting_optional_field
    @river.interested_in 'frequent_renter'
    @service.define_singleton_method :packet do |send_port, packet, warnings|
      refute_messages warnings
      packet.frequent_renter = 'platinum'
    end
    @rapids_connection.received_message SOLUTION_STRING
  end

  def test_validation_chaining
    @river
        .require('need', 'user_id')
        .forbid('contributing_services', 'missing_key')
        .interested_in('frequent_renter')
        .require('solutions')
    @service.define_singleton_method :packet do |send_port, packet, warnings|
      refute_messages warnings
    end
    @rapids_connection.received_message SOLUTION_STRING
  end

  def test_read_count_incremented
    @service.define_singleton_method :packet do |send_port, packet, warnings|
      refute_messages warnings
      assert_match ':3', packet.to_json
    end
    @rapids_connection.received_message SOLUTION_STRING
  end

  def test_service_recorded_in_packet
    @service.define_singleton_method :packet do |send_port, packet, warnings|
      refute_messages warnings
      assert_match 'test_service', packet.to_json
    end
    @rapids_connection.received_message SOLUTION_STRING
  end

  def test_json_rendering
    @river.require 'need'
    @service.define_singleton_method :packet do |send_port, packet, warnings|
      refute_messages warnings
      packet.need = 'airline_discount'
      original_json = JSON.parse(SOLUTION_STRING)
      original_json['system_read_count'] = 3
      original_json['need'] = 'airline_discount'
      original_json['contributing_services'] = ['test_service_']
      assert_equal original_json, JSON.parse(packet.to_json)
    end
    @rapids_connection.received_message SOLUTION_STRING
  end

  private

    class TestRapids
      include RapidsRivers::RapidsConnection
    end

    class TestService

      require 'securerandom'
      attr_reader :service_name

      def initialize test_instance
        @test = test_instance
        @service_name = 'test_service_' # + SecureRandom.uuid
      end

      def packet rapids_connection, packet, warnings
        throw "Unexpected invocation of Service::packet. Warnings were:\n#{warnings}"
      end

      def on_error rapids_connection, errors
        throw "Unexpected invocation of Service::on_error. Errors detected were:\n#{errors}"
      end

      private

        def refute_messages packet_problems
          @test.refute packet_problems.messages?, packet_problems.to_s
        end

        def assert_errors packet_problems
          @test.assert packet_problems.errors?, packet_problems.to_s
        end

        def assert_equal expected, actual
          @test.assert_equal expected, actual
        end

        def assert_match expected_contained_string, actual_string
          @test.assert_match expected_contained_string, actual_string
        end

    end

end
