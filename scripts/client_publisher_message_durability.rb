#!/usr/bin/env ruby
require 'bunny'
require 'open3'

MESSAGES_TO_PUBLISH = 500_000

# TEST 1
conn1 = Bunny.new(hostname: 'localhost', automatic_recovery: true)
conn1.start
chan1 = conn1.create_channel
x1 = chan1.direct('amq.direct')
q1 = chan1.queue('noconfirms_single_host', durable: true, arguments: {'x-ha-policy': 'all'}).bind(x1, routing_key: 'noconfirms_single_host')
puts 'Test 1: Fire and Forget to Single Host'
puts "Publishing #{MESSAGES_TO_PUBLISH} to #{q1.name} with confirm_select: #{chan1.using_publisher_confirmations?}"
begin
  MESSAGES_TO_PUBLISH.times.each do |msg|
    x1.publish("noconfirm: #{msg}", routing_key: 'noconfirms_single_host')

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

  sleep 1
  puts "Processed all messages to #{q1.name}. #{q1.message_count}/#{MESSAGES_TO_PUBLISH} in queue. #{MESSAGES_TO_PUBLISH - q1.message_count} messages lost."
  q1.purge
rescue Exception
  puts 'Exception in Test 1'
ensure
  conn1.close
  puts '=> Finished Test 1'
end

# TEST 2
conn2 = Bunny.new(hostname: 'localhost', automatic_recovery: true)
conn2.start
chan2 = conn2.create_channel
x2 = chan2.direct('amq.direct')
q2 = chan2.queue('confirms_single_host', durable: true, arguments: {'x-ha-policy': 'all'}).bind(x2, routing_key: 'confirms_single_host')
chan2.confirm_select
puts 'Test 2: Publish with Publisher Confirms to Single Host'
puts "Test 2: Publishing #{MESSAGES_TO_PUBLISH} to #{q2.name} with confirm_select: #{chan2.using_publisher_confirmations?}"
begin
  MESSAGES_TO_PUBLISH.times.each do |msg|
    x2.publish('', routing_key: 'confirms_single_host')

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
  success = chan2.wait_for_confirms
  puts "All messages delivered? #{success}, amount: #{chan2.nacked_set.length}"
  sleep 1
  puts "Processed all messages to #{q2.name}. #{q2.message_count}/#{MESSAGES_TO_PUBLISH} in queue. #{MESSAGES_TO_PUBLISH - q2.message_count} messages lost."
  q2.purge
rescue Exception
  puts 'Exception in Test 2'
ensure
  conn2.close
  puts '=> Finished Test 2'
end

# TEST 3
conn3 = Bunny.new(addresses: %w[localhost:5673 localhost:5674 localhost:5675], automatic_recovery: true)
conn3.start
chan3 = conn3.create_channel
x3 = chan3.direct('amq.direct')
q3 = chan3.queue('noconfirms_array_hosts', durable: true, arguments: {'x-ha-policy': 'all'}).bind(x3, routing_key: 'noconfirms_array_hosts')
puts 'Test 3: Fire and Forget to Array of Hosts'
puts "Publishing #{MESSAGES_TO_PUBLISH} to #{q3.name} with confirm_select: #{chan3.using_publisher_confirmations?}"
begin
  MESSAGES_TO_PUBLISH.times.each do |msg|
    x3.publish('', routing_key: 'noconfirms_array_hosts')

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

  sleep 1
  puts "Processed all messages to #{q3.name}. #{q3.message_count}/#{MESSAGES_TO_PUBLISH} in queue. #{MESSAGES_TO_PUBLISH - q3.message_count} messages lost."
  q3.purge
rescue Exception
  puts 'Exception in Test 3'
ensure
  conn3.close
  puts '=> Finished Test 3'
end


# TEST 4
conn4 = Bunny.new(addresses: %w[localhost:5673 localhost:5674 localhost:5675], automatic_recovery: true)
conn4.start
chan4 = conn4.create_channel
x4 = chan4.direct('amq.direct')
q4 = chan4.queue('confirms_array_hosts', durable: true, arguments: {'x-ha-policy': 'all'}).bind(x4, routing_key: 'confirms_array_hosts')
chan.confirm_select
puts 'Test 4: Publish with Publisher Confirms to Array of Hosts'
puts "Publishing #{MESSAGES_TO_PUBLISH} to #{q4.name} with confirm_select: #{chan4.using_publisher_confirmations?}"
begin
  MESSAGES_TO_PUBLISH.times.each do |msg|
    x4.publish('', routing_key: 'confirms_array_hosts')

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
  success = chan4.wait_for_confirms
  puts "All messages delivered? #{success}, amount: #{chan4.nacked_set.length}"
  sleep 1
  puts "Processed all messages to #{q4.name}. #{q4.message_count}/#{MESSAGES_TO_PUBLISH} in queue. #{MESSAGES_TO_PUBLISH - q4.message_count} messages lost."
  q4.purge
rescue Exception
  puts 'Exception in Test 4'
ensure
  conn4.close
  puts '=> Finished Test 4'
end
