require 'rubygems'
require 'snmp'
require 'yaml'

varbinds = []
SNMP::Manager.open do |snmp|
  snmp.walk("ifTable") do |vb|
    varbinds << [vb.name.to_s, vb.value.to_s, vb.value.class.to_s]
  end
end

puts varbinds.to_yaml

