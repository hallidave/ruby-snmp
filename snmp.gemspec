# frozen_string_literal: true
$:.unshift File.expand_path("../lib", __FILE__)

require_relative 'lib/snmp/version'

PKG_FILES = [
    'Rakefile',
    'README.rdoc',
    'MIT-LICENSE',
    'lib/**/*.rb',
    'test/**/test*.rb',
    'test/**/*.yaml',
    'examples/*.rb',
    'data/**/*.yaml']

Gem::Specification.new do |s|
    s.platform = Gem::Platform::RUBY
    s.summary = "A Ruby implementation of SNMP (the Simple Network Management Protocol)."
    s.name = 'snmp'
    s.version = SNMP::VERSION
    s.files = PKG_FILES.to_a
    s.extra_rdoc_files = ['README.rdoc']
    s.rdoc_options << '--main' << 'README.rdoc' <<
                      '--title' << 'SNMP Library for Ruby'
    s.description = "A Ruby implementation of SNMP (the Simple Network Management Protocol)."
    s.author = 'Dave Halliday'
    s.email = 'hallidave@gmail.com'
    s.homepage = 'https://github.com/hallidave/ruby-snmp'
    s.license = 'MIT'
    s.required_ruby_version = '>= 1.9.0'

    s.add_development_dependency("rake")
    s.add_development_dependency("bundler")
    s.add_development_dependency("minitest")
    s.add_development_dependency("rdoc")
end
