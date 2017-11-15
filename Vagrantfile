# encoding: utf-8
# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'json'

current_dir    = File.dirname(File.expand_path(__FILE__))
file           = File.read("#{current_dir}/variables.json")
variables      = JSON.parse(file)
created_at     = variables['created_at']
profile        = ENV['BLACKARCH_PROFILE'] || "core"
machine_name   = "blackarch-#{profile}"

Vagrant.configure("2") do |config|
  config.vm.network "forwarded_port", guest: 9392, host_ip: "127.0.0.1", host: 9392
  config.vm.define "#{machine_name}" do |blackarch|
    blackarch.vm.box = "#{machine_name}-#{created_at}-x86_64"
    blackarch.ssh.forward_agent = true
    blackarch.ssh.forward_x11 = true
    blackarch.vm.provider :virtualbox do |virtualbox|
      blackarch.vm.box_url = "file:///#{current_dir}/output/#{machine_name}-#{created_at}-x86_64-virtualbox.box"
      virtualbox.name = "#{machine_name}"
      virtualbox.memory = 1024
    end
  end
end
