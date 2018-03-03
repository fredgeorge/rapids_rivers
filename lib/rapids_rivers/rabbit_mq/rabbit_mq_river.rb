require_relative '../river'

# require 'pry'
# require 'pry-byebug'

module RapidsRivers

  # Understands a filtered message stream based on RabbitMQ
  class RabbitMqRiver < RapidsRivers::River

    # alias_method :parent_register, :register
    def register service
      super
      begin
        @rapids_connection.publish startup_packet(service)
        queue(service).subscribe(:block => true)  do |delivery_info, metadata, payload|
          message @rapids_connection, payload
        end
      rescue Interrupt => _
        @rapids_connection.close
        exit(0)
      end
    end

    private

      def queue service
        @queue ||= @rapids_connection.queue service_name(service)
      end

      def startup_packet service
        RapidsRivers::Packet.new(
          system: 'log',
          log_severity: 'informational',
          event_type: 'service_state',
          service_state: 'starting',
          service_name: service_name(service) )
      end

  end

end
