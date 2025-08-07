# SNMP Library for Ruby
[<img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License MIT" />](https://raw.githubusercontent.com/ruby-snmp/ruby-snmp/master/MIT-LICENSE)
[<img src="https://badge.fury.io/rb/snmp.svg" alt="Gem Version" />](https://badge.fury.io/rb/snmp)

## Summary

This library implements SNMP (the Simple Network Management Protocol).  It is
implemented in pure Ruby, so there are no dependencies on external libraries
like [net-snmp](http://www.net-snmp.org/).  You can run this library anywhere
that Ruby can run.

This release supports the following:

* The GetRequest, GetNextRequest, GetBulkRequest, SetRequest, Response
  SNMPv1_Trap, SNMPv2_Trap, and Inform PDUs
* All of the ASN.1 data types defined by SNMPv1 and SNMPv2c
* Sending informs and v1 and v2 traps
* Trap handling for informs and v1 and v2 traps
* Symbolic OID values (ie. "ifTable" instead of "1.3.6.1.2.1.2.2") as parameters to the SNMP::Manager API
* Includes symbol data files for all current IETF MIBs
* Compatible with Ruby 1.9 and higher

See the SNMP::Manager, SNMP::TrapListener, and SNMP::MIB classes and the
examples below for more details.

## Installation

You can use [RubyGems](https://rubygems.org/) to
install the latest version of the SNMP library.

```sh
gem install snmp
```

## Examples

### Get Request

Retrieve a system description.

```ruby
require 'snmp'

SNMP::Manager.open(:host => 'localhost') do |manager|
  response = manager.get(["sysDescr.0", "sysName.0"])
  response.each_varbind do |vb|
    puts "#{vb.name.to_s}  #{vb.value.to_s}  #{vb.value.asn1_type}"
  end
end
```

### Set Request

Create a varbind for setting the system name.

```ruby
require 'snmp'
include SNMP

manager = Manager.new(:host => 'localhost')
varbind = VarBind.new("1.3.6.1.2.1.1.5.0", OctetString.new("My System Name"))
manager.set(varbind)
manager.close
```

### Table Walk

Walk the ifTable.

```ruby
require 'snmp'

ifTable_columns = ["ifIndex", "ifDescr", "ifInOctets", "ifOutOctets"]
SNMP::Manager.open(:host => 'localhost') do |manager|
  manager.walk(ifTable_columns) do |row|
    row.each { |vb| print "\t#{vb.value}" }
    puts
  end
end
```

### Get-Next Request

A more difficult way to walk the ifTable.
 
```ruby
require 'snmp'
include SNMP

Manager.open(:host => 'localhost') do |manager|
  ifTable = ObjectId.new("1.3.6.1.2.1.2.2")
  next_oid = ifTable
  while next_oid.subtree_of?(ifTable)
    response = manager.get_next(next_oid)
    varbind = response.varbind_list.first
    next_oid = varbind.name
    puts varbind.to_s
  end
end
```

### Get-Bulk Request

Get interface description and admin status for 10 rows of the ifTable.

```ruby
require 'snmp'
include SNMP

ifDescr_OID = ObjectId.new("1.3.6.1.2.1.2.2.1.2")
  ifAdminStatus_OID = ObjectId.new("1.3.6.1.2.1.2.2.1.7")
  MAX_ROWS = 10
  Manager.open(:host => 'localhost') do |manager|
  response = manager.get_bulk(0, MAX_ROWS, [ifDescr_OID, ifAdminStatus_OID])
  list = response.varbind_list
  until list.empty?
    ifDescr = list.shift
    ifAdminStatus = list.shift
    puts "#{ifDescr.value}    #{ifAdminStatus.value}"
  end
end
```

### Trap Handling

Log traps to STDOUT.

```ruby
require 'snmp'
require 'logger'

log = Logger.new(STDOUT)
m = SNMP::TrapListener.new do |manager|
  manager.on_trap_default do |trap|
    log.info trap.inspect
  end
end
m.join
```

## License

This SNMP Library is released under the MIT License.

Copyright (c) 2004-2014 David R. Halliday

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
