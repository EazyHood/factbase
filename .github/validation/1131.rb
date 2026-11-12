require 'benchmark'
require 'factbase'
require 'factbase/churn'
total = 4_000
fb = Factbase.new
[
  ['insert', ->(txn) { total.times { |i| txn.insert.id = i } }, [total, 0, 0]],
  ['modify', ->(txn) { txn.query('(always)').each { |fact| fact.ready = true } }, [0, 0, total]],
  ['delete', ->(txn) { txn.query('(always)').delete! }, [0, total, 0]]
].each do |name, op, counts|
  churn = nil
  seconds = Benchmark.realtime { churn = fb.txn { |txn| op.call(txn) } }
  raise churn.to_s unless [churn.inserted, churn.deleted, churn.added] == counts
  puts "#{name} #{total} facts: #{seconds.round(4)}s"
end
raise unless fb.size.zero?
