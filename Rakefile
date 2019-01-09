#!/env ruby
require 'rake'
require 'sys/filesystem'
require 'mkmf'
require 'json'

WORKSPACE = File.expand_path File.dirname(__FILE__)
NEEDED_FREE_SPACE = 26214400

$VAR_FILE = nil
$PYTHON = nil
$VAR_FILE = nil

desc "Check needed free space for building"
task :check_free_space do
  stat = Sys::Filesystem.stat(WORKSPACE)
  mb_available = stat.block_size * stat.blocks_available / 1024 / 1024
  puts "Free space in directory #{WORKSPACE} is #{mb_available}Mb"
  abort("For building need ~25G free space, but avalible only ~#{mb_available/1024}Gb") if mb_available < NEEDED_FREE_SPACE
end
desc "Check present python2 interpreter"
task :check_python do
  $PYTHON = find_executable 'python2'
  if $PYTHON
    puts "python interpreter detected: #{$PYTHON}"
  else
    abort("Can't find python2 executable")
  end
end

desc "Generating variables"
task :generate_variables_json => :check_python do
  url, shasum = %x[ #{$PYTHON} #{WORKSPACE}/isourl.py ].split
  json_string = {"headless" => "true", ""}
end