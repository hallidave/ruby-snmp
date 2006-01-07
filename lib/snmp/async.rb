#
# Copyright (c) 2004 David R. Halliday
# All rights reserved.
#
# This SNMP library is free software.  Redistribution is permitted under the
# same terms and conditions as the standard Ruby distribution.  See the
# COPYING file in the Ruby distribution for details.
#

require 'snmp/base'
require 'snmp/mib'

module SNMP

##
# The AsyncManager class provides a highly scalable way of making large
# numbers of SNMP requests and receiving large numbers of responses in a
# relatively short period of time.
#
class AsyncManager < ManagerBase
  
    ##
    # Default configuration.  Individual options may be overridden when
    # the Manager is created.
    #
    DefaultConfig = {
        :Transport => UDPTransport,
        :MaxReceiveBytes => 8000,
        :MibDir => MIB::DEFAULT_MIB_PATH,
        :MibModules => ["SNMPv2-SMI", "SNMPv2-MIB", "IF-MIB", "IP-MIB", "TCP-MIB", "UDP-MIB"]}

    @@request_id = RequestId.new
    
    def initialize(config = {})
        if block_given?
            warn "SNMP::Manager::new() does not take block; use SNMP::Manager::open() instead"
        end
        @config = DefaultConfig.merge(config)
        @transport = @config[:Transport].new 
        @max_bytes = @config[:MaxReceiveBytes]
        @mib = MIB.new
        load_modules(@config[:MibModules], @config[:MibDir])
    end
  
    ##
    # Get the OIDs in the object list.  Returns a RequestId.
    #
    def get(peer, object_list)
    end

    def response(request_id)
    end
  
end

end
