# ITS-Firewalling-Demo-Environment

Welcome to this small collection of scripts to provision a demo environment consisting of bunch of network hosts to experiment with various firewalling, proxy and filtering techniques.

The infrastructure is built around VirtualBox version 6. VirtualBox can be obtained from: https://www.virtualbox.org/

The following drawing provides an overview of the virtual infrastructure to be instantiated.

![Network Overview](https://github.com/peterheinrich/ITS-Firewalling-Demo-Environment/blob/main/overview.png)

## General

!!! THE SYSTEMS ARE FOR EXPERIMENTAL PURPOSES ONLY - DO NOT USE THEM IN A REAL SETTING !!!

For all machines, the default credentials are:

Username: sysadmin, Password: abc123

Username: root, Password: abc123


## Windows Users
You need to add the installation directory of VirtualBox to your path variable. 
You can use the windows terminal (cmd) to try out VBoxManage. When you enter the command, you should get usage information. If not, your path is not configured correctly.

Then start the powershell. 
If you cannot run the script then you probably have to adjust the execution policy of your profile.
Navigate to the directory where you extracted/cloned the files of this repository. Execute the script:

```
$ powershell.exe -ExecutionPolicy Bypass .\createEnvironment_windows.ps1
```

## Linux Users
Just make sure that the VBoxManage binary is in your path.
```
$ which VBoxManage
```
The command above should return the path of the binary. If not, add it to your path.

Then just run the script from a terminal
```
$ bash createEnvironment_osx_linux.sh
```

## OS X 
Nothing to be done - the scripts should work out of the box.

```
$ sh createEnvironment_osx_linux.sh
```
