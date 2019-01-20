# encoding: utf-8
# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'json'

PROFILE_ENV = 'BLACKARCH_PROFILE'
WORKSPACE = File.expand_path File.dirname(__FILE__)
VAR_FILE = File.join WORKSPACE, "variables.json"

def created_at
  JSON.parse(File.read VAR_FILE)['created_at']
end

def profile(name=nil)
  name || ENV[PROFILE_ENV] || "core"
end

def machine_name(profile_name=nil)
  "blackarch-#{profile(profile_name)}"
end

def box_name(profile_name=nil)
  "#{machine_name(profile_name)}-#{created_at}-x86_64-virtualbox"
end

def box_file(profile_name=nil)
  "#{box_name(profile_name)}.box"
end