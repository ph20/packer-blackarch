#!/env ruby
require 'rake'
require 'sys/filesystem'
require 'mkmf'
require 'json'

WORKSPACE = File.expand_path File.dirname(__FILE__)
NEEDED_FREE_SPACE = 26214400
PACKER_TEMPLATE = File.join WORKSPACE, "blackarch-template.json"

VAR_FILE = File.join WORKSPACE, "variables.json"
$PYTHON = nil
$PACKER = nil


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

desc "Check present packer-io"
task :check_packer do
  $PACKER = find_executable 'packer-io'
  if $PACKER
    puts "packer-io detected: #{$PACKER}"
  else
    abort("Can't find packer-io executable")
  end
end

desc "Generating variables"
task :generate_variables => :check_python do
  iso_url, iso_checksum = %x[ #{$PYTHON} #{WORKSPACE}/isourl.py ].split
  json_struct = { :headless => 'true',
                  :created_at => Time.now.strftime("%Y%d%m"),
                  :iso_checksum => iso_checksum,
                  :iso_url => iso_url }
  File.write VAR_FILE, json_struct.to_json

end

desc "Build base vagrant box"
task :build_core => [:generate_variables, :check_packer] do
  was_good = system("#{$PACKER} build -var-file=#{VAR_FILE} -only=virtualbox-iso #{PACKER_TEMPLATE}")
end


def clear(path)
  files = Dir.glob(path) #will build an array of the full filepath & filename(s)
  files.each do |f|
    puts
    File.delete(f)
  end
end
desc "Clear"
task :clear do
  `rm -Rf ./output/*.box ./packer_cache/ ./.vagrant/ ./variables.json`
end