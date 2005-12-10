require 'snmp'
require 'test/unit'

include SNMP 

class GetNextTransport
    
    attr_accessor :count
    
    def initialize(host, port)
    end
    
    def close
    end
    
    def send(data)
        @data = data
    end
    
    def recv(max_bytes)
        response = Message.decode(@data).response
        if $transport_pdu_count > 0
            response.pdu.each_varbind do |vb|
                vb.name << 1    
            end
            $transport_pdu_count -= 1
        else
            response.pdu.each_varbind do |vb|
                vb.name = ObjectId.new("1.3.6.9999")    
            end
        end     
        response.encode[0,max_bytes]
    end
end


class TestWalk < Test::Unit::TestCase

    def test_single_object
        $transport_pdu_count = 3
        list = []
        manager.walk("ifTable") do |vb|
            assert(vb.kind_of?(VarBind), "Expected a VarBind")
            list << vb
        end
        assert_equal(3, list.length)    

        $transport_pdu_count = 3
        list = []
        manager.walk(ObjectId.new("1.3.4.5")) do |vb|
            assert(vb.kind_of?(VarBind), "Expected a VarBind")
            list << vb
        end
        assert_equal(3, list.length)    
    end
    
    def test_single_object_list
        $transport_pdu_count = 1
        executed_block = false
        manager.walk(["1.3.6.1"]) do |vb_list|
            executed_block = true
            assert_equal(1, vb_list.length)
            assert_equal("1.3.6.1.1", vb_list.first.name.to_s)
        end
        assert(executed_block, "Did not execute block")
    end
        
    def test_object_list
        $transport_pdu_count = 3
        list1 = []
        list2 = []
        manager.walk(["ifIndex", "ifDescr"]) do |vb1, vb2|
            list1 << vb1
            list2 << vb2
        end
        assert_equal(3, list1.length)    
        assert_equal(3, list2.length)    
    end
    
    def test_empty
        $transport_pdu_count = 0
        manager.walk("1.2.3.4") do |vb|
            fail("Expected block to not be executed")
        end
    end
    
    def test_one
        $transport_pdu_count = 1
        list = []
        manager.walk(["1.3.6.1", "1.3.6.2"]) do |vb|
            assert_equal("1.3.6.1.1", vb[0].name.to_s)
            assert_equal("1.3.6.2.1", vb[1].name.to_s)
            list << vb
        end
        assert_equal(1, list.length)    
    end
    
    private
    
    def manager
        Manager.new(:Transport => GetNextTransport)
    end
    
end
