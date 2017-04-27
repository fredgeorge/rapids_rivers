#!/usr/bin/env ruby
# encoding: utf-8

# Copyright (c) 2017 by Fred George.

# For debugging...
# require 'pry'
# require 'pry-nav'

require 'rapids_rivers'

# Produces a steady stream of messages on an event bus
class Producer
  attr_reader :service_name

def initialize(host_ip, port)
    @rapids_connection = RapidsRivers::RabbitMqRapids.new(host_ip, port)
    @service_name = 'producer'
  end

  def start
    loop do
      @rapids_connection.publish packet
      puts " [<] Published a packet on the bus:\n\t     #{packet.to_json}"
      sleep 5
    end
  end

  private

    def packet
      RapidsRivers::Packet.new name: 'producer'
    end

end

Producer.new(ARGV.shift, ARGV.shift).start
