require 'json'

module RapidsRivers

  # Understands a specifc message
  class Packet
    # The following keys are reserved for system usage:
    VISIT_COUNT = 'system_read_count'
    CONTRIBUTING_SERVICES = 'contributing_services'

    attr_reader :contributing_services, :system_read_count
    protected :contributing_services

    def initialize(json_hash)
      @json_hash = json_hash
      @system_read_count = (@json_hash[VISIT_COUNT] || -1) + 1
      @contributing_services = @json_hash[CONTRIBUTING_SERVICES] || []
      @used_keys = [VISIT_COUNT, CONTRIBUTING_SERVICES]
    end

    def used_key(key)
      @used_keys << key.to_s
    end

    def clone_with_name(service_name)
      self.clone.tap { |packet_copy| packet_copy.contributing_services << service_name }
    end

    def to_json
      @used_keys.each { |key| @json_hash[key] = instance_variable_get("@#{key}".to_sym) if instance_variable_get("@#{key}".to_sym) }
      @json_hash.to_json
    end

    def to_s
      "Packet (in JSON): #{self.to_json}"
    end

  end

end
