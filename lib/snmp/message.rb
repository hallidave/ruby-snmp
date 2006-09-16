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
    
class MessageFactory
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
            security_params, remainder = decode_octet_string(remainder)
            raise UnsupportedVersion, version
            # MessageV3.new(version, ...)
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

class MessageV3
end               

end # module SNMP
