#!/bin/bash
echo This script will delete all ECK pods from kubernetes, this WILL break any Elastic Stack components you have, regardless of how you installed them.
read -p "Press ^C to stop or any key to continue ..."

echo First check that kubectl is working in WSL, otherwise configure it from windows.
KUBECTLEXEC=/usr/local/bin/kubectl
if ([ -f "$KUBECTLEXEC" ] && [ -x "$KUBECTLEXEC" ]); then
    echo "Good: File '$KUBECTLEXEC' is executable"
else
    echo "WARNING: File '$KUBECTLEXEC' is not executable or not found, now trying to download it."

	echo
	echo Install kubectl cli
	echo
	curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
	chmod +x ./kubectl
	sudo mv ./kubectl /usr/local/bin/kubectl
fi
KUBECONFIG=~/.kube/config
if ([ -f "$KUBECONFIG" ]); then
    echo "Good: File '$KUBECONFIG' exists"
else
    echo "WARNING: File '$KUBECONFIG' is not available, now trying to create it."
	echo
	echo Copy windows config
	echo
	mkdir ~/.kube
	WINUSERNAME=$(cmd.exe /c "echo %USERNAME%")
	WINUSERNAME=${WINUSERNAME%$'\r'}   # Remove trailing return.
	WINUSERNAME=${WINUSERNAME%$'\n'}   # Remove trailing newline.
	cp /mnt/c/Users/$WINUSERNAME/.kube/config ~/.kube

	echo Set kubectl context
	kubectl config use-context docker-for-desktop
fi

echo Check that kubectl works.
kubectl cluster-info | grep "running"

echo Get all objects before delete
kubectl get all --all-namespaces

echo Delete ECK components

kubectl delete -f configFilebeat.yaml
kubectl delete -f configMetricbeat.yaml
kubectl delete -f configElastic.yaml
kubectl delete -f configKibana.yaml
kubectl delete -f https://download.elastic.co/downloads/eck/1.0.0/all-in-one.yaml

echo Get all objects after delete
kubectl get all --all-namespaces
