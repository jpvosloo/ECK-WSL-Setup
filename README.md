# Elastic Cloud on WSL 2 for Docker-Desktop
Install Elastic Cloud on Windows 10 WSL 2 with full cluster logging.

Prerequisite
Configure WSL 2 and Docker-Desktop with Kubernetes enabled.

Steps\
Clone this git repo\
Open WSL command line\
In the Kubernetes subfolder run:\
bash ./deleteelasticcloud.sh  

DELETE everything\
This will delete all the ECK kubectl components previously created.\
bash ./setupelasticcloud.sh  


# Elastic Cloud on WSL 2 for Canonical MicroK8s
WARNING: This is still Alpha, the Docker-Desktop edition is recommended.

