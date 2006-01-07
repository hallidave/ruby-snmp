require 'snmp'

SNMP::Manager.open(:Version => :SNMPv1) do |snmp|
  snmp.trap_v1(
    "enterprises.9",
    "10.1.2.3",
    :enterpriseSpecific,
     42,
    12345,
    [SNMP::VarBind.new("1.3.6.1.2.3.4", SNMP::Integer.new(1))])
end
