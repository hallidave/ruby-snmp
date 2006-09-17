#
# Copyright (c) 2004-2006 David R. Halliday
# All rights reserved.
#
# This SNMP library is free software.  Redistribution is permitted under the
# same terms and conditions as the standard Ruby distribution.  See the
# COPYING file in the Ruby distribution for details.
#

require 'snmp/ber'
require 'snmp/pdu'

module SNMP

class InvalidMsgFlags < RuntimeError; end
class UnsupportedSecurityModel < RuntimeError; end
    
class MessageFactory
    
    USM_SECURITY_MODEL = 3
    
    def create(pdu, options)
        version = options[:version]
        raise ArgumentError, "missing ':version' option" unless version
        if version == :SNMPv1 || version == :SNMPv2c
            community = options[:community]
            raise ArgumentError, "missing ':community' option" unless community
            Message.new(version, community, pdu)
        else
            raise UnsupportedVersion, version
        end
    end
    
    def decode(data)
        message_data, remainder = decode_sequence(data)
        assert_no_remainder(remainder)
        version, remainder = decode_version(message_data)
        if version == :SNMPv3
            header_data, remainder = decode_sequence(remainder)
            header = decode_v3_header(header_data)
            sm = header.security_model
            raise UnsupportedSecurityModel, "unknown model: #{sm}" if sm != USM_SECURITY_MODEL
            security_params, remainder = decode_octet_string(remainder)
            security_model = USM.decode(security_params)
            pdu_data, remainder = decode_sequence(remainder)
            context_engine_id, context_name, pdu = decode_scoped_pdu(version, pdu_data)
            assert_no_remainder(remainder)
            MessageV3.new(header, security_model, context_engine_id, context_name, pdu)
        else
            community, remainder = decode_octet_string(remainder)
            pdu, remainder = decode_pdu(version, remainder)
            assert_no_remainder(remainder)
            Message.new(version, community, pdu)
        end
    end

    def decode_version(data)
        version_data, remainder = decode_integer(data)
        if version_data == SNMP_V1
            version = :SNMPv1
        elsif version_data == SNMP_V2C
            version = :SNMPv2c
        elsif version_data == SNMP_V3
            version = :SNMPv3    
        else
            raise UnsupportedVersion, version_data.to_s
        end
        return version, remainder
    end
    
    def decode_v3_header(data)
        id, remainder = decode_integer(data)
        max_size, remainder = decode_integer(remainder)
        flags, remainder = decode_octet_string(remainder)
        security_model, remainder = decode_integer(remainder)
        assert_no_remainder(remainder)
        return MessageV3Header.new(id, max_size, flags, security_model)
    end
    
    def decode_scoped_pdu(version, data)
        context_engine_id, remainder = decode_octet_string(data)
        context_name, remainder = decode_octet_string(remainder)
        pdu, remainder = decode_pdu(version, remainder)
        assert_no_remainder(remainder)
        return context_engine_id, context_name, pdu
    end
        
    def decode_pdu(version, data)
        pdu_tag, pdu_data, remainder = decode_tlv(data)
        case pdu_tag
        when GetRequest_PDU_TAG
            pdu = PDU.decode(GetRequest, pdu_data)
        when GetNextRequest_PDU_TAG
            pdu = PDU.decode(GetNextRequest, pdu_data)
        when Response_PDU_TAG
            pdu = PDU.decode(Response, pdu_data)
        when SetRequest_PDU_TAG
            pdu = PDU.decode(SetRequest, pdu_data)
        when SNMPv1_Trap_PDU_TAG
            raise InvalidPduTag, "SNMPv1-trap not valid for #{version.to_s}" if version != :SNMPv1
            pdu = SNMPv1_Trap.decode(pdu_data)
        when GetBulkRequest_PDU_TAG
            raise InvalidPduTag, "get-bulk not valid for #{version.to_s}" if version != :SNMPv2c
            pdu = PDU.decode(GetBulkRequest, pdu_data)
        when InformRequest_PDU_TAG
            raise InvalidPduTag, "inform not valid for #{version.to_s}" if version != :SNMPv2c
            pdu = PDU.decode(InformRequest, pdu_data)
        when SNMPv2_Trap_PDU_TAG
            raise InvalidPduTag, "SNMPv2c-trap not valid for #{version.to_s}" if version != :SNMPv2c
            pdu = PDU.decode(SNMPv2_Trap, pdu_data)
        else
            raise UnsupportedPduTag, pdu_tag.to_s
        end
        return pdu, remainder
    end
end

class Message
    attr_reader :version
    attr_reader :community
    attr_reader :pdu
    
    def initialize(version, community, pdu)
        @version = version
        @community = community
        @pdu = pdu
    end

    def response
        Message.new(@version, @community, Response.from_pdu(@pdu))
    end
    
    def encode_version(version)
        if version == :SNMPv1
            encode_integer(SNMP_V1)
        elsif version == :SNMPv2c
            encode_integer(SNMP_V2C)
        else
            raise UnsupportedVersion, version.to_s
        end
    end
    
    def encode
        data = encode_version(@version)
        data << encode_octet_string(@community)
        data << @pdu.encode
        encode_sequence(data)
    end
end

class MessageV3Header < Struct.new(:request_id, :max_size, :flags, :security_model)

    AUTH_BIT_MASK = 0x01
    PRIV_BIT_MASK = 0x02
    REPORTABLE_BIT_MASK = 0x04
    
    def initialize(*args)
        super
        raise InvalidMessageFlags, "size of msgFlags must be one octet" if self.flags.size != 1
    end
    
    def auth
        self.flags[0] & AUTH_BIT_MASK == AUTH_BIT_MASK
    end
    
    def priv
        self.flags[0] & PRIV_BIT_MASK == PRIV_BIT_MASK
    end
    
    def reportable
        self.flags[0] & REPORTABLE_BIT_MASK == REPORTABLE_BIT_MASK
    end
end

class MessageV3 
    attr_reader :request_id
    attr_reader :max_size
    attr_reader :security_model
    attr_reader :context_engine_id
    attr_reader :context_name
    attr_reader :pdu
                         
    def initialize(header, security_model, context_engine_id, context_name, pdu)
        @request_id = header.request_id
        @max_size = header.max_size
        @auth = header.auth
        @priv = header.priv
        @reportable = header.reportable
        @security_model = security_model
        @context_engine_id = context_engine_id
        @context_name = context_name
        @pdu = pdu
    end
    
    def version
        :SNMPv3
    end
    
    def auth?
        @auth
    end
    
    def priv?
        @priv
    end
    
    def reportable?
        @reportable
    end
end               

class USM < Struct.new(:engine_id, :engine_boots, :engine_time, :user_name, :auth_params, :priv_params)
    def self.decode(data)
        seq_data, remainder = decode_sequence(data)
        engine_id, remainder = decode_octet_string(seq_data)
        engine_boots, remainder = decode_integer(remainder)
        engine_time, remainder = decode_integer(remainder)
        user_name, remainder = decode_octet_string(remainder)
        auth_params, remainder = decode_octet_string(remainder)
        priv_params, remainder = decode_octet_string(remainder)
        assert_no_remainder(remainder) 
        USM.new(engine_id, engine_boots, engine_time, user_name, auth_params, priv_params)
   end
end

end # module SNMP
