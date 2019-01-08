#!/env ruby
require 'rake'
require 'sys/filesystem'

NEEDED_FREE_SPACE = 26214400
$VAR_FILE = nil

desc "Check needed free space for building"
task :check_free_space do
  work_path = File.expand_path File.dirname(__FILE__)
  stat = Sys::Filesystem.stat("/")
  mb_available = stat.block_size * stat.blocks_available / 1024 / 1024
  puts "Free space in directory #{work_path} is #{mb_available}Mb"
  abort("For building need ~25G free space, but avalible only ~#{mb_available/1024}Gb") if mb_available < NEEDED_FREE_SPACE
end