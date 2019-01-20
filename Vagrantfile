# encoding: utf-8
# -*- mode: ruby -*-
# vi: set ft=ruby :

require_relative 'myfun'

Vagrant.configure("2") do |config|
  config.vm.network "forwarded_port", guest: 9392, host_ip: "127.0.0.1", host: 9392
  config.vm.define "#{machine_name}" do |blackarch|
    blackarch.vm.box = box_name
    blackarch.ssh.forward_agent = true
    blackarch.ssh.forward_x11 = true
    blackarch.vm.provider :virtualbox do |virtualbox|
      blackarch.vm.box_url = "file:///#{WORKSPACE}/output/#{box_file}"
      virtualbox.name = "#{machine_name}"
      virtualbox.memory = 1024
    end
  end
end
