# encoding: utf-8
# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'json'

current_dir    = File.dirname(File.expand_path(__FILE__))
file           = File.read("#{current_dir}/variables.json")
variables      = JSON.parse(file)
created_at     = variables['created_at']

Vagrant.configure("2") do |config|
  config.vm.box = "testing/blackarch-core-#{created_at}-x86_64"
  config.vm.box_url = "file:///#{current_dir}/output/blackarch-core-#{created_at}-x86_64-virtualbox.box"
end
