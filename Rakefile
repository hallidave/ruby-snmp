require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/clean'

require 'rubygems/package_task'

# test target
Rake::TestTask.new do |test|
    test.libs  << "lib"
end

# package target
CLEAN.include 'pkg'
CLEAN.include 'doc'
CLEAN.include 'web/site'

spec = Gem::Specification.load "snmp.gemspec"

Gem::PackageTask.new(spec) do |package|
    package.need_zip = false
    package.need_tar = false
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
  ROOT_PATH = File.dirname(File.expand_path(__FILE__))
  SRC_DIR = ROOT_PATH + "/web/content"
  DEST_DIR = ROOT_PATH + "/web/site"

  rm_rf DEST_DIR
  mkdir_p DEST_DIR

  Dir.glob(SRC_DIR + "/*").each do |name|
    puts "#{name}...copying"
    FileUtils.cp(name, DEST_DIR + "/" + File.basename(name))
  end

  puts "Documentation...copying"
  cp_r(ROOT_PATH + "/doc", DEST_DIR + "/doc")
end
