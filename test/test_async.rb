require 'test/unit'
require 'snmp/async'

class AsyncTest < Test::Unit::TestCase 
    
    include SNMP
    
    def setup
        @manager = AsyncManager.new(:Transport => EchoTransport)
    end
    
    def test_get
    end
    
end
