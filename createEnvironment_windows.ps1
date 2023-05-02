$filePath = "debian-10.10.0-amd64-netinst.iso"
$debianURL = "https://cdimage.debian.org/cdimage/archive/10.10.0/amd64/iso-cd/debian-10.10.0-amd64-netinst.iso"


function CreateVMUnattended {

  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [string]$filePath,
    [Parameter(Mandatory)]
    [string]$debianURL,
    [Parameter(Mandatory)]
    [string]$machineName,    
    [Parameter(Mandatory)]
    [string]$template    
  )
  
  Write-Host '================================================================================'
  Write-Host '=== Creating and Installing '$machineName
  Write-Host '================================================================================'

  # Download installation meddium if necessary
  if (Test-Path($filePath)) {
    Write-Host 'Skipping download,'$filePath' already exists'
  }
  else {
    Import-Module BitsTransfer
    Write-Host 'Downloading Debian ISO-Image '$debianURL
    Start-BitsTransfer -Source $debianURL -Destination $filePath
  }
  # Create and configure the machine
  Write-Host '=== Creating VM '$machineName
  VBoxManage createvm --name $machineName --ostype Debian_64 --register 
  Write-Host '=== Turning ioapic on'
  VBoxManage modifyvm $machineName --ioapic on 
  Write-Host '=== Enabling dual core CPU'
  VBoxManage modifyvm $machineName --cpus 2 
  Write-Host '=== Setting memory to 1G for installation'
  VBoxManage modifyvm $machineName --memory 1024 --vram 16 
  Write-Host '=== Adding a NAT network to the machine'
  VBoxManage modifyvm $machineName --nic1 nat 
  Write-Host '=== Adding a SATA controller to the machine'
  VBoxManage storagectl $machineName --name SATA  --add sata --controller IntelAhci
  Write-Host '=== Creating virual system disk'
  VBoxManage createmedium disk --filename "$home\VirtualBox VMs\$machineName\$machineName-SATA0.vdi"  --format VDI --size 8192
  Write-Host '=== Attaching disk to SATA interface'
  VBoxManage storageattach $machineName --storagectl SATA --port 0 --device 0 --type hdd --medium "$home\VirtualBox VMs\$machineName\$machineName-SATA0.vdi"
  Write-Host '=== Preparing unattended Debian installation'
  $tempPath = ([System.IO.Path]::GetTempPath()+'~'+([System.IO.Path]::GetRandomFileName()))
  mkdir $tempPath
  VBoxManage unattended install $machineName --auxiliary-base-path $tempPath/ --user=sysadmin --password=abc123 --country=CH --time-zone=UTC --hostname=$machineName.local --iso=$filePath --package-selection-adjustment=minimal --post-install-template $template
  # (Get-Content -Path $tempPath\isolinux-isolinux.cfg) -replace "^default vesa.*","default install" | Set-Content $tempPath\isolinux-isolinux.cfg
  Write-Host '=== Starting vm'
  
  # Engage the unattended installation
  VBoxManage startvm $machineName
  Write-Host '=== Waiting for installation to complete'
}

function WaitVMShutdown {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [string]$machineName
  )
  
  # Poll machine state until everything is finished and the machine is shut down completely!
  while((VBoxManage showvminfo $machineName | findstr State).split(" ")[23] -eq "running") {
    Start-Sleep -Seconds 1
  }
  while((VBoxManage showvminfo $machineName | findstr State).split(" ")[23] -ne "powered") {
    Start-Sleep -Seconds 1
  }
  
  Write-Host '================================================================================'
  Write-Host '=== Provisioning of '$machineName' done!'
  Write-Host '================================================================================'
}

# Create and install all machines in parallel
CreateVMUnattended -filePath $filePath -debianURL $debianURL -machineName "dc-server" -template dc-server-install.sh
WaitVMShutdown -machineName "dc-server"
Start-Sleep -Seconds 10

CreateVMUnattended -filePath $filePath -debianURL $debianURL -machineName "dc-router" -template dc-router-install.sh
WaitVMShutdown -machineName "dc-router"
Start-Sleep -Seconds 10

CreateVMUnattended -filePath $filePath -debianURL $debianURL -machineName "local-router" -template local-router-install.sh
WaitVMShutdown -machineName "local-router"
Start-Sleep -Seconds 10

CreateVMUnattended -filePath $filePath -debianURL $debianURL -machineName "local-client" -template local-client-install.sh
WaitVMShutdown -machineName "local-client"
Start-Sleep -Seconds 10

CreateVMUnattended -filePath $filePath -debianURL $debianURL -machineName "firewall" -template firewall-install.sh
WaitVMShutdown -machineName "firewall"
Start-Sleep -Seconds 10

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
