#
# Copyright (c) 2006 David R. Halliday
# All rights reserved.
#
# This SNMP library is free software.  Redistribution is permitted under the
# same terms and conditions as the standard Ruby distribution.  See the
# COPYING file in the Ruby distribution for details.
#

require 'thread'

module SNMP

class RequestTimeout < RuntimeError; end

##
# Wrap socket so that it can be easily substituted for testing or for
# using other transport types (e.g. TCP)
#
class UDPTransport
    def initialize
        @socket = UDPSocket.open
    end

    def close
        @socket.close
    end

    def send(data, host, port)
        @socket.send(data, 0, host, port)
    end

    def recv(max_bytes)
        @socket.recv(max_bytes)
    end
end

##
# Message transport that simply echos back exactly what it receives.  It's
# not thread safe, so it's probably only useful for testing.
#
class EchoTransport
    def initialize
    end
    
    def close
    end
    
    def send(data, host, port)
        @data = data
    end
    
    def recv(max_bytes)
        SNMP::Message.decode(@data).response.encode[0,max_bytes]
    end
end

##
# Manage a request-id in the range 1..2**31-1
#
class RequestId
    MAX_REQUEST_ID = 2**31

    def initialize
        @lock = Mutex.new
        @request_id = rand(MAX_REQUEST_ID)
    end

    def next
        @lock.synchronize do
            @request_id += 1
            @request_id = 1 if @request_id == MAX_REQUEST_ID
            return  @request_id
        end
    end

    def force_next(next_id)
        new_request_id = next_id.to_i
        if new_request_id < 1 || new_request_id >= MAX_REQUEST_ID
            raise "Invalid request id: #{new_request_id}"
        end
        new_request_id = MAX_REQUEST_ID if new_request_id == 1
        @lock.synchronize do
            @request_id = new_request_id - 1
        end
    end
end


class ManagerBase

    ##
    # Retrieves the current configuration of this Manager.
    #
    attr_reader :config
    
    ##
    # Retrieves the MIB for this Manager.
    #
    attr_reader :mib

    def initialize
        @mib = MIB.new
    end
    
    def load_modules(module_list, mib_dir)
        module_list.each { |m| @mib.load_module(m, mib_dir) }
    end
end

end
