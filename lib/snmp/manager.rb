#
# Copyright (c) 2004 David R. Halliday
# All rights reserved.
#
# This SNMP library is free software.  Redistribution is permitted under the
# same terms and conditions as the standard Ruby distribution.  See the
# COPYING file in the Ruby distribution for details.
#

require 'snmp/pdu'
require 'snmp/mib'
require 'socket'
require 'timeout'
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
    
##
# == SNMP Manager
#
# This class provides a manager for interacting with a single SNMP agent.
#
# = Example
#
#    require 'snmp'
#
#    manager = SNMP::Manager.new(:Host => 'localhost', :Port => 1061)
#    response = manager.get(["1.3.6.1.2.1.1.1.0", "1.3.6.1.2.1.1.2.0"])
#    response.each_varbind {|vb| puts vb.inspect}
#    manager.close
#
# == Symbolic Object Names
# 
# Symbolic names for SNMP object IDs can be used as parameters to the
# APIs in this class if the MIB modules are imported and the names of the
# MIBs are included in the MibModules configuration parameter.
#
# See MIB.varbind_list for a description of valid parameter formats.
#
# The following modules are loaded by default: "SNMPv2-MIB", "IF-MIB",
# "IP-MIB", "TCP-MIB", "UDP-MIB".  All of the current IETF MIBs have been
# imported and are available for loading.
#
# Additional modules may be imported using the MIB class.  The
# current implementation of the importing code requires that the
# external 'smidump' tool is available in your PATH. This tool can be 
# obtained from the libsmi website at
# http://www.ibr.cs.tu-bs.de/projects/libsmi/ .
#
# = Example
#
# Do this once:
#
#   SNMP::MIB.import_module(MY_MODULE_FILENAME, MIB_OUTPUT_DIR)
#
# Include your module in MibModules each time you create a Manager:
#
#   SNMP::Manager.new(:Host => 'localhost', :MibDir => MIB_OUTPUT_DIR,
#                     :MibModules => ["MY-MODULE-MIB", "SNMPv2-MIB", ...])
#

class Manager

    ##
    # Default configuration.  Individual options may be overridden when
    # the Manager is created.
    #
    DefaultConfig = {
        :Host => 'localhost',
        :Port => 161,
        :TrapPort => 162,
        :Community => 'public',
        :WriteCommunity => nil,
        :Version => :SNMPv2c,
        :Timeout => 1,
        :Retries => 5,
        :Transport => UDPTransport,
        :MaxReceiveBytes => 8000,
        :MibDir => MIB::DEFAULT_MIB_PATH,
        :MibModules => ["SNMPv2-MIB", "IF-MIB", "IP-MIB", "TCP-MIB", "UDP-MIB"]}

    @@request_id = RequestId.new
    
    ##
    # Retrieves the current configuration of this Manager.
    #
    attr_reader :config
    
    ##
    # Retrieves the MIB for this Manager.
    #
    attr_reader :mib
    
    def initialize(config = {})
        if block_given?
            warn "SNMP::Manager::new() does not take block; use SNMP::Manager::open() instead"
        end
        @config = DefaultConfig.merge(config)
        @config[:WriteCommunity] = @config[:WriteCommunity] || @config[:Community]
        @host = @config[:Host]
        @port = @config[:Port]
        @trap_port = @config[:TrapPort]
        @community = @config[:Community]
        @write_community = @config[:WriteCommunity]
        @snmp_version = @config[:Version]
        @timeout = @config[:Timeout]
        @retries = @config[:Retries]
        @transport = @config[:Transport].new 
        @max_bytes = @config[:MaxReceiveBytes]
        @mib = MIB.new
        load_modules(@config[:MibModules], @config[:MibDir])
    end
    
    ##
    # Creates a Manager but also takes an optional block and automatically
    # closes the transport connection used by this manager after the block
    # completes.
    #
    def self.open(config = {})
        manager = Manager.new(config)
        if block_given?
            begin
                yield manager
            ensure
                manager.close
            end
        end
    end
    
    ##
    # Close the transport connection for this manager.
    #
    def close
        @transport.close
    end
            
    def load_module(name)
        @mib.load_module(name)
    end
    
    ##
    # Sends a get request for the supplied list of ObjectId or VarBind
    # objects.
    #
    # Returns a Response PDU with the results of the request.
    #
    def get(object_list)
        varbind_list = @mib.varbind_list(object_list, :NullValue)
        request = GetRequest.new(@@request_id.next, varbind_list)
        try_request(request)
    end

    ##
    # Sends a get request for the supplied list of ObjectId or VarBind
    # objects.
    #
    # Returns a list of the varbind values only, not the entire response,
    # in the same order as the initial object_list.  This method is
    # useful for retrieving scalar values.
    #
    # For example:
    #
    #   SNMP::Manager.open(:Host => "localhost") do |manager|
    #     puts manager.get_value("sysDescr.0")
    #   end
    #
    def get_value(object_list)
        if object_list.respond_to? :to_ary
            get(object_list).vb_list.collect { |vb| vb.value }
        else
            get(object_list).vb_list.first.value
        end
    end
    
    ##
    # Sends a get-next request for the supplied list of ObjectId or VarBind
    # objects.
    #
    # Returns a Response PDU with the results of the request.
    #
    def get_next(object_list)
        varbind_list = @mib.varbind_list(object_list, :NullValue)
        request = GetNextRequest.new(@@request_id.next, varbind_list)
        try_request(request)
    end
    
    ##
    # Sends a get-bulk request.  The non_repeaters parameter specifies
    # the number of objects in the object_list to be retrieved once.  The
    # remaining objects in the list will be retrieved up to the number of
    # times specified by max_repetitions.
    #
    def get_bulk(non_repeaters, max_repetitions, object_list)
        varbind_list = @mib.varbind_list(object_list, :NullValue)
        request = GetBulkRequest.new(
                @@request_id.next,
                varbind_list,
                non_repeaters,
                max_repetitions)
        try_request(request)
    end
    
    ##
    # Sends a set request using the supplied list of VarBind objects.
    #
    # Returns a Response PDU with the results of the request.
    #
    def set(object_list)
        varbind_list = @mib.varbind_list(object_list, :KeepValue)
        request = SetRequest.new(@@request_id.next, varbind_list)
        try_request(request, @write_community)
    end

    ##
    # Sends an SNMPv2c style trap.
    #
    # sys_up_time: an integer respresenting the number of hundredths of
    #              a second that this system has been up
    #
    # trap_oid:    an ObjectId or String with the OID identifier for this
    #              trap
    #
    # object_list: a list of additional varbinds to send with the trap 
    #
    def trap_v2(sys_up_time, trap_oid, object_list=[])
        vb_list = create_trap_vb_list(sys_up_time, trap_oid, object_list)
        trap = SNMPv2_Trap.new(@@request_id.next, vb_list)
        send_request(trap, @community, @host, @trap_port)
    end
                
    ##
    # Sends an inform request using the supplied list 
    #
    # sys_up_time: an integer respresenting the number of hundredths of
    #              a second that this system has been up
    #
    # trap_oid:    an ObjectId or String with the OID identifier for this
    #              inform request
    #
    # object_list: a list of additional varbinds to send with the inform 
    #
    def inform(sys_up_time, trap_oid, object_list=[])
        vb_list = create_trap_vb_list(sys_up_time, trap_oid, object_list)
        request = InformRequest.new(@@request_id.next, vb_list)
        try_request(request, @community, @host, @trap_port)
    end
    
    ##
    # Helper method for building VarBindList for trap and inform requests.
    #
    def create_trap_vb_list(sys_up_time, trap_oid, object_list)
        vb_args = @mib.varbind_list(object_list, :KeepValue)
        uptime_vb = VarBind.new(SNMP::SYS_UP_TIME_OID, TimeTicks.new(sys_up_time.to_int))
        trap_vb = VarBind.new(SNMP::SNMP_TRAP_OID_OID, @mib.oid(trap_oid))
        VarBindList.new([uptime_vb, trap_vb, *vb_args])
    end
    
    ##
    # Walks a list of ObjectId or VarBind objects using get_next until
    # the response to the first OID in the list reaches the end of its
    # MIB subtree.
    #
    # The varbinds from each get_next are yielded to the given block as
    # they are retrieved.  The result is yielded as a VarBind when walking
    # a single object or as a VarBindList when walking a list of objects.
    #
    # Normally this method is used for walking tables by providing an
    # ObjectId for each column of the table.
    #
    # For example:
    #
    #   SNMP::Manager.open(:Host => "localhost") do |manager|
    #     manager.walk("ifTable") { |vb| puts vb }
    #   end
    #
    #   SNMP::Manager.open(:Host => "localhost") do |manager|
    #     manager.walk(["ifIndex", "ifDescr"]) do |index, descr| 
    #       puts "#{index.value} #{descr.value}"
    #     end
    #   end
    #
    def walk(object_list)
        raise ArgumentError, "expected a block to be given" unless block_given?
        varbind_list = @mib.varbind_list(object_list, :NullValue)
        start_oid = varbind_list.first.name
        last_oid = start_oid
        loop do
            varbind_list = get_next(varbind_list).varbind_list
            first_vb = varbind_list.first
            break if EndOfMibView == first_vb.value 
            stop_oid = first_vb.name
            if stop_oid <= last_oid
                warn "OIDs are not increasing, #{last_oid} followed by #{stop_oid}"
                break
            end
            break unless stop_oid.subtree_of?(start_oid)
            last_oid = stop_oid
            if object_list.respond_to?(:to_str) ||
               object_list.respond_to?(:to_varbind)
            then
                yield first_vb
            else
                yield varbind_list
            end
        end
    end
    
    ##
    # Set the next request-id instead of letting it be generated
    # automatically. This method is useful for testing and debugging.
    #
    def next_request_id=(request_id)
        @@request_id.force_next(request_id)
    end
    
    private

    def warn(message)
        trace = caller(2)
        location = trace[0].sub(/:in.*/,'')
        Kernel::warn "#{location}: warning: #{message}"
    end
    
    def load_modules(module_list, mib_dir)
        module_list.each { |m| @mib.load_module(m, mib_dir) }
    end
    
    def try_request(request, community=@community, host=@host, port=@port)
        (@retries + 1).times do |n|
            send_request(request, community, host, port)
            begin
                timeout(@timeout) do
                    return get_response(request)
                end
            rescue Timeout::Error
                # no action - try again
            rescue => e
                warn e.to_s
            end
        end
        raise RequestTimeout, "host #{@config[:Host]} not responding", caller
    end
    
    def send_request(request, community, host, port)
        message = Message.new(@snmp_version, community, request)
        @transport.send(message.encode, host, port)
    end
    
    ##
    # Wait until response arrives.  Ignore responses with mismatched IDs;
    # these responses are typically from previous requests that timed out
    # or almost timed out.
    #
    def get_response(request)
        begin
            data = @transport.recv(@max_bytes)
            message = Message.decode(data)
            response = message.pdu
        end until request.request_id == response.request_id
        response
    end
end

class UDPServerTransport
    def initialize(port)
        @socket = UDPSocket.open
        @socket.bind('localhost', port)
    end
    
    def close
        @socket.close
    end
    
    def recvfrom(max_bytes)
        data, host_info = @socket.recvfrom(max_bytes)
        flags, host_socket, host_name, host_ip = host_info
        return data, host_ip
    end
end

##
# == SNMP Trap Listener
#
# Listens to a socket and processes received traps in a separate thread.
#
# === Example
#
#   require 'snmp'
#
#   m = SNMP::TrapListener.new(:Port => 1062, :Community => 'public') do |manager|
#     manager.on_trap_default { |trap| p trap }
#   end
#   m.join
#
class TrapListener
    DefaultConfig = {
        :Port => 162,
        :Community => 'public',
        :ServerTransport => UDPServerTransport,
        :MaxReceiveBytes => 8000}

    NULL_HANDLER = Proc.new {}
    
    ##
    # Start a trap handler thread.  If a block is provided then the block
    # is executed before trap handling begins.  This block is typically used
    # to define the trap handler blocks.
    #
    # The trap handler blocks execute in the context of the trap handler thread.
    #
    # The most specific trap handler is executed when a trap arrives.  Only one
    # handler is executed.  The handlers are checked in the following order:
    #
    # 1. handler for a specific OID
    # 2. handler for a specific SNMP version
    # 3. default handler
    #
    def initialize(config={}, &block)
        @config = DefaultConfig.dup.update(config)
        @transport = @config[:ServerTransport].new(@config[:Port])
        @max_bytes = @config[:MaxReceiveBytes]
        @handler_init = block
        @oid_handler = {}
        @v1_handler = nil
        @v2c_handler = nil
        @default_handler = nil
        @lock = Mutex.new
        @handler_thread = Thread.new(self) { |m| process_traps(m) }
    end
    
    ##
    # Define the default trap handler.  The default trap handler block is
    # executed only if no other block is applicable.  This handler should
    # expect to receive both SNMPv1_Trap and SNMPv2_Trap objects.
    #
    def on_trap_default(&block)
        raise ArgumentError, "a block must be provided" unless block
        @lock.synchronize { @default_handler = block }
    end
    
    ##
    # Define a trap handler block for a specific trap ObjectId.  This handler
    # only applies to SNMPv2 traps.  Note that symbolic OIDs are not
    # supported by this method (like in the SNMP.Manager class).
    #
    def on_trap(object_id, &block)
        raise ArgumentError, "a block must be provided" unless block
        @lock.synchronize { @oid_handler[ObjectId.new(object_id)] = block }
    end

    ##
    # Define a trap handler block for all SNMPv1 traps.  The trap yielded
    # to the block will always be an SNMPv1_Trap.
    #
    def on_trap_v1(&block)
        raise ArgumentError, "a block must be provided" unless block
        @lock.synchronize { @v1_handler = block }
    end
    
    ##
    # Define a trap handler block for all SNMPv2c traps.  The trap yielded
    # to the block will always be an SNMPv2_Trap.
    #
    def on_trap_v2c(&block)
        raise ArgumentError, "a block must be provided" unless block
        @lock.synchronize { @v2c_handler = block }
    end
    
    ##
    # Joins the current thread to the trap handler thread.
    #
    # See also Thread#join.
    #
    def join
        @handler_thread.join
    end
    
    ##
    # Stops the trap handler thread and releases the socket.
    #
    # See also Thread#exit.
    #
    def exit
        @handler_thread.exit
        @transport.close
    end
    
    alias kill exit
    alias terminate exit
    
    private
    
    def process_traps(trap_listener)
        @handler_init.call(trap_listener) if @handler_init
        loop do
            data, source_ip = @transport.recvfrom(@max_bytes)
            begin
                message = Message.decode(data)
                if @config[:Community] == message.community
                    trap = message.pdu
                    trap.source_ip = source_ip
                    select_handler(trap).call(trap)
                end
            rescue => e
                puts "Error handling trap: #{e}"
                puts e.backtrace.join("\n")
                puts "Received data:"
                p data  
            end
        end
    end
    
    def select_handler(trap)
        @lock.synchronize do
            if trap.kind_of?(SNMPv2_Trap)
                oid = trap.trap_oid
                if @oid_handler[oid]
                    return @oid_handler[oid]
                elsif @v2c_handler
                    return @v2c_handler
                elsif @default_handler
                    return @default_handler
                else
                    return NULL_HANDLER
                end
            elsif trap.kind_of?(SNMPv1_Trap)
                if @v1_handler
                    return @v1_handler
                elsif @default_handler
                    return @default_handler
                else
                    return NULL_HANDLER
                end
            else
                return NULL_HANDLER
            end
        end
    end
end

end
