require 'snmp'
require 'drb'
require 'logger'

class AgentServer

  include SNMP

  def initialize(port=1061, max_packet=8000)
    @log = Logger.new(STDOUT)
    @lock = Mutex.new
    @socket = UDPSocket.open
    @socket.bind(nil, port)
    @max_packet = max_packet
    @last_pdu = nil
    @last_request_id = nil
  end

  def start
    @thread = Thread.new do
      @log.info "Started"
      loop do
        begin
          data, remote_info = @socket.recvfrom(@max_packet)
          @log.info "Received #{data.length} bytes"
          self.last_pdu = data
          #@log.debug "Decoding message"
          message = Message.decode(data)
          self.last_request_id = message.pdu.request_id
          response = message.response
          fill_varbinds(response.pdu)
          #@log.debug "Encoding response"
          encoded_message = response.encode
          #@log.debug "Sending response"
          n = @socket.send(encoded_message, 0, remote_info[3], remote_info[1])
          @log.info "Sent #{n} bytes"
        rescue => e
          @log.error e
        end
      end
    end
  end

  def join
    @thread.join
  end

  def kill
    @thread.kill
  end

  def last_pdu=(last_pdu)
    @lock.synchronize do
      @last_pdu = last_pdu
    end
  end

  def last_pdu
    @lock.synchronize do
      return @last_pdu
    end
  end

  def last_request_id=(last_request_id)
    @lock.synchronize do
      @last_request_id = last_request_id
    end
  end

  def last_request_id
    @lock.synchronize do
      return @last_request_id
    end
  end

  private

    TEST_STRING = "X" * 255

    RESPONSE_MAP = {
      "1.3.6.1.2.1.2.1.0" => Integer32.new(2147483647),    # ifNumber.0
      "1.3.6.1.2.1.1.1.0" => OctetString.new(TEST_STRING),  # sysDescr.0
      "1.3.6.1.2.1.1.2.0" => ObjectId.new("0.0"),  # sysObjectID.0
      "1.3.6.1.2.1.4.20.1.255.255.255.255" => IpAddress.new("255.255.255.255"),  # ipAddrEntry.255.255.255.255
      "1.3.6.1.2.1.11.1.0" => Counter32.new(4294967295),    # snmpInPkts.0
      "1.3.6.1.2.1.1.3.0" => TimeTicks.new(4294967295),     # sysUpTime.0
      "1.3.6.1.2.1.31.1.1.1.6.1" => Counter64.new(18446744073709551615),    # ifHCInOctets.1
      "1.3.6.1.2.1.2.2.1.5.1" => Gauge32.new(4294967295) #ifSpeed.1
    }

    def fill_varbinds(pdu)
      pdu.each_varbind do |varbind|
        p varbind
        varbind.value = RESPONSE_MAP[varbind.name.to_s]
      end
    end


end

class ServerApi

  def initialize(server)
    @server = server
  end

  def hello
    @server.hello
  end

  def last_pdu
    @server.last_pdu
  end

  def last_request_id
    @server.last_request_id
  end

end

server = AgentServer.new
server.start

server_api = ServerApi.new(server)
DRb.start_service('druby://localhost:9000', server_api)
DRb.thread.join
