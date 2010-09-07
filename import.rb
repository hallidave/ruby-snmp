require 'snmp/mib'

Dir['/opt/local/share/mibs/ietf/*'].each do |file|
  print file
  if (File.basename(file) == 'DOT12-RPTR-MIB')
    puts " (skipping)"
  else
    puts
    SNMP::MIB::import_module(file)
  end
end
