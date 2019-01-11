#!/env ruby
require 'rake'
require 'sys/filesystem'
require 'json'
require 'mkmf'

WORKSPACE = File.expand_path File.dirname(__FILE__)
NEEDED_FREE_SPACE = 25600
PACKER_TEMPLATE = File.join WORKSPACE, "blackarch-template.json"

VAR_FILE = File.join WORKSPACE, "variables.json"
$PYTHON = nil
$PACKER = nil
$VAGRANT = nil

def created_at
  JSON.parse(File.read VAR_FILE)['created_at']
end

def run(cmd, env = {})
  system(env, cmd) || abort("error: #{cmd}")
end

def run_script(script)
  run("#{$VAGRANT} ssh --command='/usr/bin/sudo /bin/bash /vagrant/scripts/#{script}'")
end

namespace :check do

  desc "Check needed free space for building"
  task :free_space do
    stat = Sys::Filesystem.stat(WORKSPACE)
    mb_available = stat.block_size * stat.blocks_available / 1024 / 1024
    puts "Free space in directory #{WORKSPACE} is #{mb_available/1024}Gb"
    abort("For building need ~25G free space, but avalible only ~#{mb_available/1024}Gb") if mb_available < NEEDED_FREE_SPACE
  end

  desc "Check present python2 interpreter"
  task :python do
    $PYTHON = find_executable 'python2'
    abort("Can't find python2 executable") if $PYTHON.nil?
    version = %x{ #{$PYTHON} -c "import sys; print(sys.version.split()[0])" }
    abort("Can't detect version of #{$PYTHON}") if version.strip.empty?
    puts "    #{$PYTHON}\n    Python #{version}"
  end

  desc "Check present packer-io"
  task :packer do
    $PACKER = find_executable('packer') || find_executable('packer-io')
    abort("Can't find packer-io executable") if $PACKER.nil?
    version = %x{ #{$PACKER} version }
    abort("Can't detect version of #{$PACKER}") if version.strip.empty?
    puts "     #{$PACKER}\n    #{version}"
  end

  desc "Check present vagrant"
  task :vagrant do
    $VAGRANT = find_executable 'vagrant'
    abort("Can't find vagrant executable") if $VAGRANT.nil?
    version = %x{ #{$VAGRANT} --version }
    abort("Can't detect version of #{$VAGRANT}") if version.strip.empty?
    puts "    #{$VAGRANT}\n    #{version}"
  end
end
desc "check all requirements"
task :check => ["check:python",
                "check:packer",
                "check:vagrant",
                "check:free_space"]

desc "Generating variables"
task :generate_variables => "check:python" do
  iso_url, iso_checksum = %x[ #{$PYTHON} #{WORKSPACE}/isourl.py ].split
  json_struct = { :headless => 'true',
                  :created_at => Time.now.strftime("%Y%d%m"),
                  :iso_checksum => iso_checksum,
                  :iso_url => iso_url }
  puts "Variables wroten to file '#{VAR_FILE}'"
  File.write VAR_FILE, json_struct.to_json

end

namespace :build do

  desc "Build core"
  task :core => [:generate_variables, "check:packer"] do
    was_good = system("#{$PACKER} build #{ENV['PACKERARGS'] || ""} -var-file=#{VAR_FILE} -only=virtualbox-iso #{PACKER_TEMPLATE}")
  end

  desc 'Build common'
  task :common => ["check:vagrant", :generate_variables, :core] do
    run "#{$VAGRANT} up", {'BLACKARCH_PROFILE' => 'core'}
    run_script 'deploy-common.sh'
    run_script 'configure.sh'
    run_script 'cleanup.sh'
    run "#{$VAGRANT} package --output ./output/blackarch-common-#{created_at}-x86_64-virtualbox.box", {'BLACKARCH_PROFILE' => 'core'}
    run "#{$VAGRANT}  destroy -f", {'BLACKARCH_PROFILE' => 'core'}
  end

  desc 'Build full'
  task :full => ["check:vagrant", :generate_variables, :core] do
    run "#{$VAGRANT} up", {'BLACKARCH_PROFILE' => 'common'}
    run_script 'deploy-full.sh'
    run_script 'cleanup.sh'
    run "#{$VAGRANT} package --output ./output/blackarch-full-#{created_at}-x86_64-virtualbox.box", {'BLACKARCH_PROFILE' => 'common'}
    run "#{$VAGRANT}  destroy -f", {'BLACKARCH_PROFILE' => 'common'}
  end

end

desc "Build all"
task :build => ["build:core",
                "build:common",
                "build:full"]

desc "Clear"
task :clear do
  `rm -vRf ./output/*.box ./packer_cache/ ./.vagrant/ ./variables.json`
end