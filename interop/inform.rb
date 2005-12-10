# sudo snmptrapd -Lf out.txt
# tail -f out.txt

require 'snmp'

SNMP::Manager.open() do |snmp|
    snmp.inform(12345, "1.3.6.1")
    snmp.inform(12345, "1.3.6.1", ["1.3.6.1.2"])
    snmp.trap_v2(12345, "1.3.6.1")
    snmp.trap_v2(12345, "1.3.6.1", ["1.3.6.1.2", "1.3.6.1.3"])
end
