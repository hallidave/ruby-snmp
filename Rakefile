require 'rake'
require 'rake/testtask'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/clean'

# test target
Rake::TestTask.new do |test|
    test.libs  << "lib"
end

# package target
PKG_VERSION = '1.0.3'
PKG_FILES = FileList[
    'Rakefile',
    'README.rdoc',
    'setup.rb',
    'lib/**/*.rb',
    'test/**/test*.rb',
    'test/**/*.yaml',
    'examples/*.rb',
    'data/**/*.yaml']

CLEAN.include 'pkg'
CLEAN.include 'doc'
CLEAN.include 'web/web'

spec = Gem::Specification.new do |s|
    s.platform = Gem::Platform::RUBY
    s.summary = "A Ruby implementation of SNMP (the Simple Network Management Protocol)."
    s.name = 'snmp'
    s.version = PKG_VERSION
    s.files = PKG_FILES.to_a
    s.has_rdoc = true
    s.extra_rdoc_files = ['README.rdoc']    
    s.rdoc_options << '--main' << 'README.rdoc' <<
                      '--title' << 'SNMP Library for Ruby'
    s.description = "A Ruby implementation of SNMP (the Simple Network Management Protocol)."
    s.author = 'Dave Halliday'
    s.email = 'hallidave@gmail.com'
    s.rubyforge_project = 'snmplib'
    s.homepage = 'http://snmplib.rubyforge.org'
end

Rake::GemPackageTask.new(spec) do |package|
    package.need_zip = true
    package.need_tar = true
end

# rdoc, clobber_rdoc, rerdoc targets
Rake::RDocTask.new do |doc|
    doc.rdoc_dir = "doc"
    doc.main = "README.rdoc"
    doc.rdoc_files.include('README.rdoc', 'lib/**/*.rb')
    doc.title = "SNMP Library for Ruby"
end 

desc "Generate website content"
task :web => :rdoc do
    require 'web/generate'  
end

