IMAGE_NAME = "generic/debian10"

Vagrant.configure("2") do |config|
	config.vm.box = IMAGE_NAME
	config.vm.define "lemp" do |bd|
		bd.vm.provider "virtualbox" do |v|
			v.name = "lemp"
			v.memory = 1024
			v.cpus = 1
		end
		bd.vm.network "private_network", ip: "10.50.10.100"
		bd.vm.hostname = "lemp"
		bd.vm.synced_folder ".", "/vagrant", type: "virtualbox"
		bd.vm.provision :shell, path: "./files/user-slave.sh", args: "appuser"
		bd.vm.provision :shell, privileged: true, path: "./files/lemp.sh"
	end

	config.vm.define "hybris" do |master|
		master.vm.provider "virtualbox" do |v|
			v.name = "hybris"
			v.memory = 2048
			v.cpus = 2
		end
		master.vm.hostname = "hybris"
		master.vm.network "private_network", ip: "10.50.10.10"
		master.vm.network "forwarded_port", guest: 9001, host: 9001, host_ip: "private_network"
		master.vm.network "forwarded_port", guest: 9002, host: 9002, host_ip: "private_network" 
		master.vm.synced_folder ".", "/vagrant", type: "virtualbox"
		master.vm.provision :shell, path: "./files/user-slave.sh", args: "appuser"
		master.vm.provision :shell, path: "./files/bootstrap.sh", privileged: true 
		master.vm.provision :shell, privileged: true, inline: <<-SHELL
				/opt/hybrisstart.sh &> /tmp/start.out&
			SHELL
	end
end
