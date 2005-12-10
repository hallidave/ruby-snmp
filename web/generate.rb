require 'fileutils'

ROOT_PATH = File.dirname(File.expand_path(__FILE__))
SRC_DIR = ROOT_PATH + "/content"
DEST_DIR = ROOT_PATH + "/web"

FileUtils.rm_rf DEST_DIR
FileUtils.mkdir_p DEST_DIR

Dir.glob(SRC_DIR + "/*").each do |name|
    puts "#{name}...copying"
    FileUtils.cp(name, DEST_DIR + "/" + File.basename(name))
end

puts "Documentation...copying"
FileUtils.cp_r(ROOT_PATH + "/../doc", DEST_DIR + "/doc")



