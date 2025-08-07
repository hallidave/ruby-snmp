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
