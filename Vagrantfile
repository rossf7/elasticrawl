# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.

  # Fix DNS issues with Ubuntu 12.04 by always using host's resolver
  config.vm.provider "virtualbox" do |vbox|
    vbox.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
  end

  # Elasticrawl launches Hadoop jobs for the CommonCrawl dataset using the AWS EMR service.
  config.vm.define :elasticrawl do |elasticrawl|
    elasticrawl.vm.box = "elasticrawl"

    # Ubuntu Server 12.04 LTS
    elasticrawl.vm.box_url = "http://files.vagrantup.com/precise64.box"

    # Network config
    elasticrawl.vm.network :public_network

    # Provision using Chef Solo
    elasticrawl.vm.provision "chef_solo" do |chef|
      chef.cookbooks_path = "cookbooks"
      chef.add_recipe "apt"
      chef.add_recipe "build-essential"
      chef.add_recipe "ruby_build"
      chef.add_recipe "rbenv::user"
      chef.add_recipe "git"
      chef.add_recipe "vim"

      chef.json = {
        "rbenv" => {
          "user_installs" => [
            {
              "user" => "vagrant",
              "rubies" => ["1.9.3-p551", "2.0.0-p598", "2.1.5"],
              "global" => "2.1.5",
              "gems" => {
                "1.9.3-p551" => [
                  { "name" => "bundler" }
                ],
                "2.0.0-p598" => [
                  { "name" => "bundler" }
                ],
                "2.1.5" => [
                  { "name" => "bundler" }
                ]
              }
            }
          ]
        }
      }
    end
  end
end
