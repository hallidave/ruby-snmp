# sudo snmptrapd -Lf out.txt
# tail -f out.txt

require 'snmp'

SNMP::Manager.open() do |snmp|
  snmp.inform(12345, "1.3.6.1")
  snmp.inform(12345, "1.3.6.1", ["1.3.6.1.2"])
  snmp.trap_v2(12345, "1.3.6.1")
  snmp.trap_v2(12345, "1.3.6.1", ["1.3.6.1.2", "1.3.6.1.3"])
end

SNMP::Manager.open(:version => :SNMPv1) do |snmp|
  snmp.trap_v1(
    "SNMPv2-SMI::enterprises.9",
    "127.0.0.1",
    :enterpriseSpecific,
    123,
    12345,
    ["1.3.6.1.2", "1.3.6.1.3"]
  )
end
