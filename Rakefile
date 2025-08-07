# frozen_string_literal: true

require "bundler/gem_tasks"

# Avoid using `minitest/test_task` for Ruby 2.5 and earlier
require "rake/testtask"

Rake::TestTask.new(:test) do |test|
  test.libs << "lib"
end

task default: :test

# rdoc, clobber_rdoc, rerdoc targets
require 'rdoc/task'

Rake::RDocTask.new do |doc|
  doc.rdoc_dir = "doc"
  doc.main = "README.md"
  doc.rdoc_files.include("README.md", "lib/**/*.rb")
  doc.title = "SNMP Library for Ruby"
end 

namespace :web do
  desc "Generate website content"
  task :gen => :rdoc do
    ROOT_PATH = File.dirname(File.expand_path(__FILE__))
    SRC_DIR = ROOT_PATH + "/web/content"
    DEST_DIR = ROOT_PATH + "/web/site"

    rm_rf DEST_DIR
    mkdir_p DEST_DIR

    Dir.glob(SRC_DIR + "/*").each do |name|
      puts "#{name}...copying"
      cp name, DEST_DIR + "/" + File.basename(name)
    end

    puts "Documentation...copying"
    cp_r ROOT_PATH + "/doc", DEST_DIR + "/doc"
  end

  desc "Publish website to RubyForge"
  task :publish => :gen do
    sh "scp -r web/site/* davehal@rubyforge.org:/var/www/gforge-projects/snmplib"
  end
end
