require_relative '../river'

module RapidsRivers

  # Understands a filtered message stream based on RabbitMQ
  class RabbitMqRiver < RapidsRivers::River

    alias_method :parent_register, :register
    def register service
      super
      begin
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
        @queue ||= @rapids_connection.queue service.service_name
      end

  end

end
