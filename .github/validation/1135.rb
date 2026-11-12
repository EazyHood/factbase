require 'benchmark'
require 'factbase'
require 'factbase/query'
require 'factbase/indexed/indexed_factbase'
size = 2_000
['(lt i 0)', '(always)', '(head 200 (always))'].each do |expr|
  fb = Factbase.new(Array.new(size) { |i| { 'i' => [i] } })
  removed = nil
  duration = Benchmark.realtime { removed = fb.query(expr).delete! }
  raise if fb.size + removed != size
  puts "#{expr}: deleted #{removed}, took #{duration.round(4)}s"
end
# A registered term may write through its evaluation context.
fb = Factbase.new
fb.insert.x = 1
Factbase::Term.new(:defn, [:modify_on_delete, "fb.query('(eq x 1)').each { |row| row.changed = 1 }; true"]).evaluate(nil, [], fb)
begin
  raise unless fb.query('(modify_on_delete)').delete! == 1 && fb.size.zero?
ensure
  Factbase::Term.new(:undef, [:modify_on_delete]).evaluate(nil, [], fb)
end
