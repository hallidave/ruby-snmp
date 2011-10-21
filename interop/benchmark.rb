require 'snmp'
require 'benchmark'

include SNMP

OID_STRING_LIST = ["1.3.6.1.2.1.2.1.0", "1.3.6.1.2.1.1.1.0", "1.3.6.1.2.1.1.2.0",
                   "1.3.6.1.2.1.4.20.1.255.255.255.255", "1.3.6.1.2.1.11.1.0",
                   "1.3.6.1.2.1.1.3.0"]
OID_LIST = OID_STRING_LIST.collect { |s| ObjectId.new(s) }

Manager.open(:host => 'localhost', :port => 1061) do |manager|
  r = Benchmark.measure do
    100.times { manager.get(OID_LIST) }
  end
  puts r
end
