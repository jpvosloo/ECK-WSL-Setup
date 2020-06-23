# Elastic Cloud on WSL 2 for Docker-Desktop
Install Elastic Cloud on Windows 10 WSL 2 with full cluster logging.

## Prerequisite
Configure WSL 2 and Docker-Desktop with Kubernetes enabled.

## Install ECK\
Clone this git repo\
Open WSL command line\
In the Kubernetes subfolder run:\
> bash ./setupelasticcloud.sh  

## Uninstall ECK\
This will delete all the ECK kubectl components previously created.\
> bash ./deleteelasticcloud.sh  


# Elastic Cloud on WSL 2 for Canonical MicroK8s
WARNING: This is still Alpha, the Docker-Desktop edition is recommended.

## Prerequisite
Windows 10 build 18917\

## Install ECK\
Clone this git repo\
Navigate to the MicroK8s subfolder\
Run with PowerShell:\
> Install-WslUbuntuMicroK8s.ps1\

## Uninstall ECK\
Run with PowerShell:\
> Uninstall-Ubuntu.ps1\
> Uninstall-WSL.ps1\
