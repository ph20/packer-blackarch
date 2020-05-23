Packer BlackArch
===========
[Packer](https://www.packer.io) templates for building [BlackArch](https://blackarch.org/) vagrant images.
[BlackArch](https://blackarch.org/) Linux is an [Arch Linux](https://www.archlinux.org/) -based penetration testing distribution for penetration testers and security researchers.

Building results on Vagrant Cloud
---------------------------------
- https://app.vagrantup.com/ph20/boxes/blackarch-core-x86_64
- https://app.vagrantup.com/ph20/boxes/blackarch-common-x86_64
- https://app.vagrantup.com/ph20/boxes/blackarch-full-x86_64

Usage
-----
```
# creating vagrant directory if needed
mkdir vagrant-blackarch
cd vagrant-blackarch
# initial vagrant file
vagrant init ph20/blackarch-common-x86_64
# customise Vagrantfile if needed
# start vagrant instance
vagrant up
# connect to balckarch machine
vagrant ssh
```

Building
-----
```
git clone https://github.com/ph20/packer-blackarch.git
cd packer-blackarch
# install all needed requirements regarding your linux distro
rake build
```
See all available tasks
```
# rake -T                                                                                                                                                                                                      ─╯
rake build               # Build all
rake build:common        # Build common
rake build:core          # Build core
rake build:full          # Build full
rake check               # check all requirements
rake check:free_space    # Check needed free space for building
rake check:packer        # Check present packer-io
rake check:python        # Check present python2 interpreter
rake check:vagrant       # Check present vagrant
rake clean               # Remove any temporary products / Clean builds
rake clobber             # Remove any generated files
rake generate_variables  # Generating variables
```
There avalible three build types
- `rake build:core` - core image without pentest utils but with all needed for fast install any util;
- `rake build:common` - image with common used utils (nmap, nikto, etc..);
- `rake build:full` - all avaliable BlackArch tools;

Resources used to create this:
-----------------------------
- https://github.com/elasticdog/packer-arch
- https://github.com/BlackArch/blackarch-installer

Technology stack
----------------
- `HashiCorp Packer` -  automates the creation of any type of machine image https://www.packer.io/ 
- `RAKE` - Make-like program implemented in Ruby https://ruby.github.io/rake/
- `Vagrant by HashiCorp` - an open-source software product for building and maintaining portable virtual software development environments https://www.vagrantup.com/ 

Other: [Oracle VM VirtualBox](), [Python](), [GNU Bash]()

