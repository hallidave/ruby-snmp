require 'test/unit'
require 'snmp'
require 'timeout'

class TestTrapInterop < Test::Unit::TestCase

  include SNMP

  def setup
    @queue = Queue.new
    @manager = TrapListener.new(:Host => 'localhost', :Port => 1062) do |manager|
      manager.on_trap_default do |trap|
        @queue << trap
      end
    end
  end

  def next_trap
    t=nil
    timeout(3, RuntimeError) { t = @queue.deq }
    return t
  end

  def test_v1_trap
    system("snmptrap -v 1 -c public localhost:1062 '' localhost 3 0 '' ifIndex.1 i 1")
    trap = next_trap
    assert(trap.kind_of?(SNMPv1_Trap))
    assert_equal(:linkUp, trap.generic_trap)
    assert_equal(0, trap.specific_trap)
    assert_equal(1, trap.varbind_list.length)
  end

  def test_v2c_trap
    system("snmptrap -v 2c -c public localhost:1062 1234 linkDown ifIndex.1 i 1 ifAdminStatus.1 i 2 ifOperStatus.1 i 6")
    trap = next_trap
    assert(trap.kind_of?(SNMPv2_Trap))
    assert_equal(1234, trap.sys_up_time)
    assert_equal("1.3.6.1.6.3.1.1.5.3", trap.trap_oid.to_s)
    assert_equal(5, trap.varbind_list.length)
  end

  def test_inform
    system("snmpinform -v 2c -c public localhost:1062 2176117721 linkUp ifIndex.1 i 1 ifAdminStatus.1 i 2 ifOperStatus.1 i 6")
    trap = next_trap
    assert(trap.kind_of?(InformRequest))
    assert_equal(2176117721, trap.sys_up_time)
    assert_equal("1.3.6.1.6.3.1.1.5.4", trap.trap_oid.to_s)
    assert_equal(5, trap.varbind_list.length)
  end

  def teardown
    @manager.exit
  end

end
