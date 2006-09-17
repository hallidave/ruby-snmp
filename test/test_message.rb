require "test/unit"

require "snmp/message"

class TestMessage < Test::Unit::TestCase
    def setup
        @factory = SNMP::MessageFactory.new
    end
    
    def test_message_decode_v1
        message = @factory.decode("0'\002\001\000\004\006public\240\032\002\002\003\350\002\001\000\002\001\0000\0160\f\006\010+\006\001\002\001\001\001\000\005\000")
        assert_equal(:SNMPv1, message.version)
        assert_equal("public", message.community)
        assert_equal(SNMP::GetRequest, message.pdu.class)
        varbind_list = message.pdu.vb_list;
        assert_equal(1, varbind_list.length)
        assert_equal([1,3,6,1,2,1,1,1,0], varbind_list.first.name)
        assert_equal(SNMP::Null, varbind_list.first.value)
    end

    def test_message_decode_v2c
        message = @factory.decode("0)\002\001\001\004\006public\240\034\002\0040\265\020\202\002\001\000\002\001\0000\0160\f\006\010+\006\001\002\001\001\001\000\005\000")
        assert_equal(:SNMPv2c, message.version)
        assert_equal("public", message.community)
        varbind_list = message.pdu.vb_list;
        assert_equal(1, varbind_list.length)
        assert_equal([1,3,6,1,2,1,1,1,0], varbind_list.first.name)
        assert_equal(SNMP::Null, varbind_list.first.value)
    end
    
    def test_message_decode_v3
        message = @factory.decode("0>\002\001\0030\021\002\004Q\004\242\325\002\003\000\377\343\004\001\004\002\001\003\004\0200\016\004\000\002\001\000\002\001\000\004\000\004\000\004\0000\024\004\000\004\000\240\016\002\004Q\000CR\002\001\000\002\001\0000\000")
        assert_equal(:SNMPv3, message.version)
        assert_equal(1359258325, message.request_id)
        assert_equal(65507, message.max_size) 
        assert(!message.auth?)
        assert(!message.priv?)
        assert(message.reportable?)
        assert_equal(SNMP::USM, message.security_model.class)
        assert_equal("", message.context_engine_id)
        assert_equal("", message.context_name)
        assert_equal(SNMP::GetRequest, message.pdu.class)
    end
    
    def test_encode_message
        varbind = SNMP::VarBind.new([1,3,6,1234], SNMP::OctetString.new("value"))
        list = SNMP::VarBindList.new
        list << varbind << varbind;
        pdu = SNMP::Response.new(12345, list)
        message = @factory.create(pdu, :version => :SNMPv2c, :community => "public")
        assert_equal("07\002\001\001\004\006public\242*\002\00209\002\001\000\002\001\0000\0360\r\006\004+\006\211R\004\005value0\r\006\004+\006\211R\004\005value", message.encode)
    end
end