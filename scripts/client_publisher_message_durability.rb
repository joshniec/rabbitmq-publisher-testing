#!/usr/bin/env ruby
require 'bunny'
require 'open3'

MESSAGES_TO_PUBLISH = 500_000

conn = Bunny.new(hostname: 'localhost')
conn.start
chan = conn.create_channel

x = chan.direct('amq.direct')
q_noconfirms = chan.queue('noconfirms', durable: true).bind(x, routing_key: 'noconfirms')
puts "=> Publishing #{MESSAGES_TO_PUBLISH} to #{q_noconfirms.name} with confirm_select: #{chan.using_publisher_confirmations?}"
MESSAGES_TO_PUBLISH.times.each do |msg|
  x.publish("noconfirm: #{msg}", routing_key: 'noconfirms')

  case msg
  when 100_000
    puts 'RabbitMQ: Simulating 2 node failure...'
    IO.popen('docker restart rabbitmq1')
    IO.popen('docker restart rabbitmq3')
  when 300_000
    puts 'RabbitMQ: Simulating 1 node failure...'
    IO.popen('docker restart rabbitmq2')
  end
end

sleep 0.2
puts "=> Processed all messages to #{q_noconfirms.name}. #{q_noconfirms.message_count}/#{MESSAGES_TO_PUBLISH} in queue. #{MESSAGES_TO_PUBLISH - q_noconfirm.message_count} messages lost."
q_noconfirms.purge

q_confirms = chan.queue('confirms', durable: true).bind(x, routing_key: 'confirms')
chan.confirm_select
puts "=> Publishing #{MESSAGES_TO_PUBLISH} to #{q_confirms.name} with confirm_select: #{chan.using_publisher_confirmations?}"
MESSAGES_TO_PUBLISH.times.each do |msg|
  x.publish("confirm: #{msg}", routing_key: 'confirms')

  case msg
  when 100_000
    puts 'RabbitMQ: Simulating 2 node failure...'
    IO.popen('docker restart rabbitmq1')
    IO.popen('docker restart rabbitmq3')
  when 300_000
    puts 'RabbitMQ: Simulating 1 node failure...'
    IO.popen('docker restart rabbitmq2')
  end
end

success = chan.wait_for_confirms
puts "All messages delivered? #{success}"

unless success
  chan.nacked_set.each do |msg|
    x.publish("confirm: #{msg}", routing_key: 'confirms')
  end
end

sleep 0.2
puts "=> Processed all messages to #{q_confirms.name}. #{q_confirms.message_count}/#{MESSAGES_TO_PUBLISH} in queue. #{MESSAGES_TO_PUBLISH - q_confirms.message_count} messages lost."
q_confirms.purge

conn.close
