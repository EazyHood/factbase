require 'benchmark'
require 'factbase'
require 'factbase/tallied'

source = Factbase.new
50_000.times do |id|
  fact = source.insert
  fact.id = id
  fact.name = "record #{id}"
end
bytes = source.export
target = Factbase::Tallied.new(Factbase.new)
loads = 0
trace = TracePoint.new(:call, :c_call) do |event|
  loads += 1 if event.self.equal?(Marshal) && event.method_id == :load
end
seconds = Benchmark.realtime { trace.enable { target.import(bytes) } }
raise target.churn.to_s unless target.churn.inserted == 50_000 && target.size == 50_000
puts "Imported #{target.size} facts in #{seconds.round(4)}s with #{loads} decodes"
