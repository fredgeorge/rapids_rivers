#!/usr/bin/env ruby
# encoding: utf-8

# Copyright (c) 2017 by Fred George.

require 'rapids_rivers'

# Understands offers at the corporate level
class Consumer
  attr_reader :service_name

  def initialize(host_ip, port)
    rapids_connection = RapidsRivers::RabbitMqRapids.new(host_ip, port)
    @river = RapidsRivers::RabbitMqRiver.new(rapids_connection)
    @river.require_values name: 'producer'
    @river.forbid :solution
    # @river.interested_in :solution
    @service_name = 'consumer'
  end

  def start
    puts " [*] #{@service_name} waiting for traffic on RabbitMQ event bus ... To exit press CTRL+C"
    @river.register(self)
  end

  def packet rapids_connection, packet, warnings
    packet.solution = 'result'
    rapids_connection.publish packet
    puts " [<] Published a solution on the bus:\n\t     #{packet.to_json}"
  end

  # def on_error rapids_connection, errors
  #   puts " [x] Failed river filter because:\n\t     #{errors}"
  # end

end

Consumer.new(ARGV.shift, ARGV.shift).start
