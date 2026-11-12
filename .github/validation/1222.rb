require 'benchmark'
require 'factbase'
require 'factbase/indexed/indexed_factbase'

random = Random.new(12_222)
pool = [0, 1, -5, 0.25, 10**40, 'a', 'b', Time.utc(2026), true, false, nil]
10_000.times do
  values = Array.new(random.rand(0..8)) { pool.sample(random: random) }
  results = [:sort, :minmax].map do |method|
    begin
      values.public_send(method)
      true
    rescue ArgumentError
      false
    end
  end
  raise values.inspect unless results.uniq.size == 1
end
fb = Factbase::IndexedFactbase.new(Factbase.new)
40_000.times { |value| fb.insert.x = value }
query = fb.query('(gt x 999999)')
raise unless query.count.zero?
seconds = Benchmark.realtime { 50.times { raise unless query.count.zero? } }
puts "50 warm range queries over 40000 facts: #{seconds.round(4)}s; 10000 comparability checks agree"
