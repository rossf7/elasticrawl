# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.

  # Increase RAM to 1 GB
  config.vm.provider "virtualbox" do |vbox|
    vbox.customize ["modifyvm", :id, "--memory", 1024]
  end

  # Elasticrawl launches Hadoop jobs for the CommonCrawl dataset using the AWS EMR service.
  config.vm.define :elasticrawl do |elasticrawl|
    elasticrawl.vm.box = "elasticrawl"

    # Ubuntu Server 14.04 LTS
    elasticrawl.vm.box = "ubuntu/trusty64"

    # Network config
    elasticrawl.vm.network :public_network

    # Synced folder for creating deploy packages
    elasticrawl.vm.synced_folder "../traveling-elasticrawl/", "/traveling-elasticrawl/"

    # Provision using Chef Solo
    elasticrawl.vm.provision "chef_solo" do |chef|
      chef.cookbooks_path = "cookbooks"
      chef.add_recipe "apt"
      chef.add_recipe "build-essential"
      chef.add_recipe "ruby_build"
      chef.add_recipe "ruby_rbenv::user"
      chef.add_recipe "git"
      chef.add_recipe "vim"

      chef.json = {
        "rbenv" => {
          "user_installs" => [
            {
              "user" => "vagrant",
              "rubies" => ["2.0.0-p648", "2.1.8", "2.2.4", "2.3.0"],
              "global" => "2.2.4",
              "gems" => {
                "2.0.0-p648" => [
                  { "name" => "bundler",
                    "version" => "1.11.2" }
                ],
                "2.1.8" => [
                  { "name" => "bundler",
                    "version" => "1.11.2" }
                ],
                "2.2.4" => [
                  { "name" => "bundler",
                    "version" => "1.11.2" }
                ],
                "2.3.0" => [
                  { "name" => "bundler",
                    "version" => "1.11.2" }
                ]
              }
            }
          ]
        }
      }

    end
  end
end
