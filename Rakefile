#!/env ruby
require 'rake'
require 'rake/clean'
require 'sys/filesystem'
require 'json'
require 'mkmf'
require_relative 'myfun'

NEEDED_FREE_SPACE = 25600
PACKER_TEMPLATE = File.join WORKSPACE, "blackarch-template.json"

$PYTHON = nil
$PACKER = nil
$VAGRANT = nil


class VagrantCLI

  def initialize(profile_name='core')
    @profile_name = profile_name
  end

  def cmd(command)
    system({'BLACKARCH_PROFILE' => @profile_name}, "#{$VAGRANT} #{command}") || abort("error: #{command}")
  end

  def up()
    cmd 'up'
  end

  def destroy()
    cmd 'destroy -f'
  end

  def package(target)
    cmd "package --output #{target}"
  end

  def script(name, sudo=true)
    sudo_path = sudo ? '/usr/bin/sudo' : ''
    cmd("ssh --command='#{sudo_path} /bin/bash /vagrant/scripts/#{name}'")
  end
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
task :check => ['check:python', 'check:packer', 'check:vagrant', 'check:free_space']

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

  desc "Build stage1"
  task :env => [:generate_variables, "check:packer"] do
    target = "./output/#{box_file('buildenv')}"
    if File.exist?(target)
      puts "Skip task: file #{target} already exist"
      next
    end
    was_good = system("#{$PACKER} build #{ENV['PACKERARGS'] || ""} -var-file=#{VAR_FILE} -only=virtualbox-iso #{PACKER_TEMPLATE}")
    abort('Something happened') if was_good.nil?
  end

  desc "Build core"
  task :core => [:generate_variables, "check:packer"] do
    target = "./output/#{box_file('core')}"
    if File.exist?(target)
      puts "Skip task: file #{target} already exist"
      next
    end
    was_good = system("#{$PACKER} build #{ENV['PACKERARGS'] || ""} -var-file=#{VAR_FILE} -only=vagrant #{PACKER_TEMPLATE}")
    abort('Something happened') if was_good.nil?
  end

end

desc "Build all"
task :build => "build:full"

desc "Clean builds"
task :clean => 'check:vagrant' do
  for profile_name in ['core', 'common', 'full'] do
    box = VagrantCLI.new profile_name
    box.destroy
    system "#{$VAGRANT} box remove --force --box-version=0 --provider=virtualbox #{box_name(profile_name)}"
  end
  Rake::Cleaner.cleanup_files(FileList['output/*.box', '.vagrant', 'variables.json', 'mkmf.log', 'output-virtualbox-iso'])
end

task :clean_cache do
  Rake::Cleaner.cleanup_files(FileList['packer_cache/*.iso', 'pkg_cache/*.pkg.*'])
end