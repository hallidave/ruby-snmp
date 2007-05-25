require 'snmp'

module SNMP
  class OctetString
    def to_date_time
      raise ArgumentError, "not DateAndTime format" if size != 8 and size != 11
      year = self[0] * 256 + self[1]
      month = self[2]
      day = self[3]
      hour = self[4]
      minutes = self[5]
      seconds = self[6]
      tenths = self[7]
      sprintf("%d-%d-%d,%02d:%02d:%02d.%d", year, month, day, hour, minutes, seconds, tenths)
    end
  end
end

SNMP::Manager.open(:Host => 'localhost', :MibModules => ["HOST-RESOURCES-MIB"]) do |snmp|
  response = snmp.get_value("hrSystemDate.0")
  puts response.to_date_time
end