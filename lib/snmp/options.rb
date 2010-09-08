#
# Copyright (c) 2004 David R. Halliday
# All rights reserved.
#
# This SNMP library is free software.  Redistribution is permitted under the
# same terms and conditions as the standard Ruby distribution.  See the
# COPYING file in the Ruby distribution for details.
#

module SNMP

  ##
  # Helper class for processing options Hash.
  #
  class Options #:nodoc:
    @@defaulters = {}
    @@alternates = {}

    def self.option(symbol, alternate, defaulter=nil)
      @@defaulters[symbol] = defaulter
      @@alternates[symbol] = alternate
    end

    attr_reader :applied_config

    def initialize(config)
      @config = validate_keys(config)
      @applied_config = {}
    end

    def method_missing(method, *args, &block)
      if args.size == 0
        option_value = @config[method] || @config[@@alternates[method]] || default_value(method)
        @applied_config[method] = option_value
        return option_value
      else
        super
      end
    end

    def default_value(method)
      defaulter = @@defaulters[method]
      defaulter.kind_of?(Proc) ? defaulter.call(self) : defaulter
    end

    def validate_keys(config)
      valid_symbols = @@alternates.keys + @@alternates.values
      config.each_key { |k| raise "Invalid option: #{k}" unless valid_symbols.include? k }
      config
    end
  end
end
