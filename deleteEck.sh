#!/bin/bash
KUBECTLEXEC=/usr/local/bin/kubectl
if ([ -f "$KUBECTLEXEC" ] && [ -x "$KUBECTLEXEC" ]); then
    echo "File '$KUBECTLEXEC' is executable"
else
    echo "File '$KUBECTLEXEC' is not executable or not found"

	echo
	echo install kubectl cli
	echo
	curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
	chmod +x ./kubectl
	sudo mv ./kubectl /usr/local/bin/kubectl
fi
KUBECONFIG=~/.kube/config
if ([ -f "$KUBECONFIG" ]); then
    echo "File '$KUBECONFIG' exists"
else
    echo "File '$KUBECONFIG' is not available"
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
kubectl cluster-info

echo Get all objects before delete
kubectl get all --all-namespaces

echo Delete ECK components

kubectl delete -f filebeat-kubernetes.yaml
kubectl delete -f metricbeat-kubernetes.yaml
kubectl delete -f createelastic.yaml
kubectl delete -f createkibana.yaml
kubectl delete -f https://download.elastic.co/downloads/eck/1.0.0/all-in-one.yaml

echo Get all objects after delete
kubectl get all --all-namespaces
