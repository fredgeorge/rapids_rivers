require 'bunny'

# require 'pry'
# require 'pry-byebug'

require_relative '../rapids_connection'
require_relative './rabbit_mq_river'

module RapidsRivers

  # Understands an event bus based on RabbitMQ
  class RabbitMqRapids
    include RapidsRivers::RapidsConnection

    RAPIDS = 'rapids'

    def initialize(host_ip, port)
      host_ip = host_ip || ENV['RABBITMQ_IP'] || throw("Need IP address for RabbitMQ")
      port = port || ENV['RABBITMQ_PORT'] || 5672
      @connection = Bunny.new(
        :host => host_ip,
        :port => port.to_i,
        :automatically_recover => false)
    end

    def publish(packet)
      exchange.publish packet.to_json
    end

    def queue queue_name = ""
      channel.queue(queue_name || "", exclusive: true, auto_delete: true).tap do |queue|
        queue.bind exchange
      end
    end

    def close
      channel.close
      @connection.close
    end

    private

      def channel
        return @channel if @channel
        @connection.start
        @channel = @connection.create_channel
      end

      def exchange
        @exchange ||= channel.fanout(RAPIDS, durable: true, auto_delete: true)
      end

  end

end
