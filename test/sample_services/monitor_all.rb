#!/usr/bin/env ruby
# encoding: utf-8

# Copyright (c) 2017 by Fred George.

# For debugging...
# require 'pry'
# require 'pry-byebug'

require 'securerandom'
require 'rapids_rivers'

# Understands the complete stream of messages on an event bus
class MonitorAll
  attr_reader :service_name

  def initialize(host_ip, port)
    rapids_connection = RapidsRivers::RabbitMqRapids.new(host_ip, port)
    @river = RapidsRivers::RabbitMqRiver.new(rapids_connection)
    @service_name = 'monitor_all_' + SecureRandom.uuid
  end

  def start
    puts " [*] #{@service_name} waiting for traffic on RabbitMQ event bus ... To exit press CTRL+C"
    @river.register(self)
  end

  def packet rapids_connection, packet, warnings
    puts " [*] #{warnings}"
  end

  def on_error rapids_connection, errors
    puts " [x] #{errors}"
  end

end

MonitorAll.new(ARGV.shift, ARGV.shift).start
