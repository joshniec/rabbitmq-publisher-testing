#!/usr/bin/env ruby
require 'benchmark'
require 'bunny'

conn = Bunny.new(hostname: 'localhost')
conn.start

chan = conn.create_channel
ex_noconfirm = chan.direct('noconfirm')
ex_confirms = chan.direct('confirms')

q_noconfirm = chan.queue('benchmark_noconfirm', exclusive: true).bind(ex_noconfirm)
q_confirms = chan.queue('benchmark_confirms', exclusive: true).bind(ex_confirms)

Benchmark.bm do |benchmark|
  benchmark.report('publish_noconfirm') do
    100_000.times.each do |msg|
      ex_noconfirm.publish("noconfirm: #{msg}", routing_key: q_noconfirm.name)
    end
  end

  chan.confirm_select
  benchmark.report('publisher_confirms') do
    100_000.times.each do |msg|
      ex_confirms.publish("confirm: #{msg}", routing_key: q_confirms.name)
    end
  end
end

conn.close
