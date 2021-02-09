#!/bin/bash
set -e

filePath="debian-10.8.0-amd64-netinst.iso"
debianURL="https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-10.8.0-amd64-netinst.iso"


function CreateVMUnattended() {

	filePath=$1
	debianURL=$2
	machineName=$3
	template=$4
	  
	echo '================================================================================'
	echo '=== Creating and Installing '$machineName
	echo '================================================================================'

	# Download installation meddium if necessary
	if [ -f $filePath ]; then
		echo 'Skipping download,'$filePath' already exists'
	else
		echo 'Downloading Debian ISO-Image '$debianURL
		curl -L -o $filePath $debianURL
	fi

	# Create and configure the machine
	echo '=== Creating VM '$machineName
	VBoxManage createvm --name $machineName --ostype Debian_64 --register 
	echo '=== Turning ioapic on'
	VBoxManage modifyvm $machineName --ioapic on 
	echo '=== Setting memory to 1G for installation'
	VBoxManage modifyvm $machineName --memory 1024 --vram 16 
	echo '=== Adding a NAT network to the machine'
	VBoxManage modifyvm $machineName --nic1 nat 
	echo '=== Adding a SATA controller to the machine'
	VBoxManage storagectl $machineName --name SATA  --add sata --controller IntelAhci
	echo '=== Creating virual system disk'
	VBoxManage createmedium disk --filename ~/VirtualBox\ VMs/$machineName/$machineName-SATA0.vdi  --format VDI --size 8192
	echo '=== Attaching disk to SATA interface'
	VBoxManage storageattach $machineName --storagectl SATA --port 0 --device 0 --type hdd --medium ~/VirtualBox\ VMs/$machineName/$machineName-SATA0.vdi
	echo '=== Preparing unattended Debian installation'
	tempPath=$(mktemp -d /tmp/vbunattended-XXXX) 
	mkdir -p $tempPath
	echo "TEMPDIR: " $tempPath
	VBoxManage unattended install $machineName --auxiliary-base-path $tempPath/ --user=sysadmin --password=abc123 --country=CH --time-zone=UTC --hostname=$machineName.local --iso=$filePath --package-selection-adjustment=minimal --post-install-template $template
	cp $tempPath/isolinux-isolinux.cfg $tempPath/isolinux-isolinux.cfg.orig
	cat $tempPath/isolinux-isolinux.cfg.orig | sed -e "s/^default vesa.*/default install/g" > $tempPath/isolinux-isolinux.cfg

	echo '=== Starting vm'

	# Engage the unattended installation
	VBoxManage startvm $machineName
	echo '=== Waiting for installation to complete'

}

function WaitVMShutdown() {

	machineName=$1

	# Poll machine state until everything is finished and the machine is shut down completely!
	while [ "$(VBoxManage showvminfo $machineName | grep State | cut -d " " -f 24)"  = "running" ]; do
		sleep 1
	done
	while [ "$(VBoxManage showvminfo $machineName | grep State | cut -d " " -f 24)" != "powered" ]; do
		sleep 1
	done

	echo '================================================================================'
	echo '=== Provisioning of '$machineName' done!'
	echo '================================================================================'
}

# Create and install all machines in parallel
CreateVMUnattended  $filePath  $debianURL  "dc-server"  dc-server-install.sh
CreateVMUnattended  $filePath  $debianURL  "dc-router"  dc-router-install.sh
CreateVMUnattended  $filePath  $debianURL  "local-router"  local-router-install.sh
CreateVMUnattended  $filePath  $debianURL  "local-client"  local-client-install.sh
CreateVMUnattended  $filePath  $debianURL  "firewall"  firewall-install.sh

# Just for safety ...
sleep 10

# Wait for all machines to finish installing
WaitVMShutdown  "dc-server"
WaitVMShutdown  "dc-router"
WaitVMShutdown  "local-router"
WaitVMShutdown  "local-client"
WaitVMShutdown  "firewall"

# Just for safety ...
sleep 10

# Configure our datacenter server
VBoxManage modifyvm dc-server --nic1 intnet
VBoxManage modifyvm dc-server --intnet1 net_dc
VBoxManage modifyvm dc-server --memory 256 --vram 16 

# Configure our datacenter router
VBoxManage modifyvm dc-router --nic1 intnet
VBoxManage modifyvm dc-router --intnet1 net_dc
VBoxManage modifyvm dc-router --nic2 intnet
VBoxManage modifyvm dc-router --intnet2 net_dc_ext
VBoxManage modifyvm dc-router --memory 256 --vram 16 

# Configure our local router
VBoxManage modifyvm local-router --nic1 intnet
VBoxManage modifyvm local-router --intnet1 net_local
VBoxManage modifyvm local-router --nic2 intnet
VBoxManage modifyvm local-router --intnet2 net_local_ext
VBoxManage modifyvm local-router --memory 256 --vram 16 

# Configure our local client
VBoxManage modifyvm local-client --nic1 intnet
VBoxManage modifyvm local-client --intnet1 net_local
VBoxManage modifyvm local-client --memory 256 --vram 16 

# Configure the main firewall
VBoxManage modifyvm firewall --nic1 intnet
VBoxManage modifyvm firewall --intnet1 net_dc_ext
VBoxManage modifyvm firewall --nic2 intnet
VBoxManage modifyvm firewall --intnet2 net_local_ext
VBoxManage modifyvm firewall --nic3 nat
VBoxManage modifyvm firewall --memory 256 --vram 16 
