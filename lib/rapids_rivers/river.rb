require 'json'

require_relative './rapids_connection'
require_relative './packet'
require_relative './packet_problems'

module RapidsRivers

  # Understands a filtered stream of JSON messages
  class River
    attr_reader :rapids_connection, :listening_services
    protected :rapids_connection, :listening_services

    def initialize rapids_connection, read_count_limit = 9
      @rapids_connection, @read_count_limit = rapids_connection, read_count_limit
      @listening_services = []
      @validations = []
      rapids_connection.register(self);
    end

    def message send_port, message
      packet_problems = RapidsRivers::PacketProblems.new message
      packet = validated_packet message, packet_problems
      return if packet && packet.respond_to?(:system_read_count) && packet.system_read_count > @read_count_limit
      @listening_services.each do |ls|
        next ls.packet(send_port, packet.clone_with_name(service_name(ls)), packet_problems) unless packet_problems.errors?
        next unless ls.respond_to? :on_error
        ls.on_error(send_port, packet_problems) if packet_problems.errors?
      end
    end

    def register service
      @listening_services << service
    end

    def require *keys
      keys.each do |key|
        @validations << lambda do |json_hash, packet, packet_problems|
          validate_required key, json_hash, packet_problems
          create_accessors key, json_hash, packet
        end
      end
      self
    end

    def forbid *keys
      keys.each do |key|
        @validations << lambda do |json_hash, packet, packet_problems|
          validate_missing key, json_hash, packet_problems
          create_accessors key, json_hash, packet
        end
      end
      self
    end

    def require_values(key_value_hashes)
      key_value_hashes.each do |key, value|
        @validations << lambda do |json_hash, packet, packet_problems|
          validate_value key, value, json_hash, packet_problems
          create_accessors key, json_hash, packet
        end
      end
      self
    end

    def interested_in *keys
      keys.each do |key|
        @validations << lambda do |json_hash, packet, packet_problems|
          create_accessors key, json_hash, packet
        end
      end
      self
    end

    protected

      def service_name(service)
        service.respond_to?(:service_name) ? service.service_name : '<unknown>'
      end

    private

      def validated_packet message, packet_problems
        begin
          json_hash = JSON.parse(message)
          packet = Packet.new json_hash
          @validations.each { |v| v.call json_hash, packet, packet_problems }
          packet
        rescue JSON::ParserError
          packet_problems.severe_error("Invalid JSON format. Please check syntax carefully.")
        rescue Exception => e
          packet_problems.severe_error("Packet creation issue:\n\t#{e}")
        end
      end

      def validate_required key, json_hash, packet_problems
        key = key.to_s
        return packet_problems.error "Missing required key '#{key}'" unless json_hash[key]
        return packet_problems.error "Empty required key '#{key}'" unless value?(json_hash[key])
      end

      def validate_missing key, json_hash, packet_problems
        key = key.to_s
        return unless json_hash.key? key
        return unless value?(json_hash[key])
        packet_problems.error "Forbidden key '#{key}'' detected"
      end

      def validate_value key, value, json_hash, packet_problems
        key = key.to_s
        validate_required key, json_hash, packet_problems
        return if json_hash[key] == value
        packet_problems.error "Required value of key '#{key}' is '#{json_hash[key]}', not '#{value}'"
      end

      def create_accessors key, json_hash, packet
        key = key.to_s
        packet.used_key key
        establish_variable key, json_hash[key], packet
        define_getter key, packet
        define_setter key, packet
      end

      def establish_variable key, value = nil, packet
        variable = variable(key)
        packet.instance_variable_set variable, value
      end

      def define_getter key, packet
        variable = variable(key)
        packet.define_singleton_method(key.to_sym) do
          instance_variable_get variable
        end
      end

      def define_setter key, packet
        variable = variable(key)
        packet.define_singleton_method((key + '=').to_sym) do |new_value|
          instance_variable_set variable, new_value
        end
      end

      def variable key
        ('@' + key.to_s).to_sym
      end

      def value? value_under_test
        return false if value_under_test.nil?
        return true if value_under_test.kind_of?(Numeric)
        return false if value_under_test == ''
        return false if value_under_test == []
        true
      end

  end

end
