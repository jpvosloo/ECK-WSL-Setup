#!/bin/bash
echo This script will configure ElasticSearch ECK stack on Windows 10 with WSL 2.
echo First check that kubectl is working in WSL, otherwise configure it from windows.

KUBECTLEXEC=/usr/local/bin/kubectl
if [[ $(grep Microsoft /proc/version) ]]; then
	echo "Good: Running on WSL"
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
fi

echo Check that kubectl works.
kubectl cluster-info | grep "running"

echo Setup ECK
echo Download ECK operator
kubectl apply -f https://download.elastic.co/downloads/eck/1.0.0/all-in-one.yaml
echo Create Elastic Search container
kubectl apply -f configElastic.yaml
echo Create Kibana container
kubectl apply -f configkibana.yaml

kubectl get pods
echo "Wait for pods to start"
echo "https://localhost:30218/"
echo "https://localhost:31586/"
read -p "Press any key to continue ..."

echo Get Elasticsearch password
ESPASSWRD=$(kubectl get secret elasticsearch-es-elastic-user -o=jsonpath='{.data.elastic}' | base64 -d)
echo $ESPASSWRD > "ELASTIC-""$HOSTNAME"".SECRET"
echo $ESPASSWRD

echo "Manually update the filebeat.yaml and metricbeat.yaml file with the password"
read -p "Press any key to continue ..."

#echo setup dns debug tools
#kubectl apply -f dnsutils.yaml
#kubectl exec -ti dnsutils -- sh


echo Create filebeat
kubectl apply -f configFilebeat.yaml
kubectl logs daemonset.apps/filebeat --namespace=kube-system #--follow
read -p "Press any key to resume ..."

echo Create metricbeat
kubectl apply -f configMetricbeat.yaml
kubectl logs daemonset.apps/metricbeat --namespace=kube-system

echo get all objects
kubectl get all --all-namespaces




