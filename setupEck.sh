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

echo Setup ECK
echo Download ECK operator
kubectl apply -f https://download.elastic.co/downloads/eck/1.0.0/all-in-one.yaml
echo Create Elastic Search container
kubectl apply -f createelastic.yaml
echo Create Kibana container
kubectl apply -f createkibana.yaml


echo Get Elasticsearch password
ESPASSWRD=$(kubectl get secret elasticsearch-es-elastic-user -o=jsonpath='{.data.elastic}' | base64 -d)
echo $ESPASSWRD > "ELASTIC-""$HOSTNAME"".SECRET"
echo $ESPASSWRD

kubectl get all
echo "https://localhost:30218/"
echo "https://localhost:31586/"
echo "Wait for pods to start and manually update the metricbeat.yaml file with password"
read -p "Press any key to resume ..."

#echo setup dns debug tools
#kubectl apply -f dnsutils.yaml
#kubectl exec -ti dnsutils -- sh


echo Create filebeat
kubectl apply -f filebeat-kubernetes.yaml
kubectl logs daemonset.apps/filebeat --namespace=kube-system --follow
read -p "Press any key to resume ..."

echo Create metricbeat
kubectl apply -f metricbeat-kubernetes.yaml
kubectl logs daemonset.apps/metricbeat --namespace=kube-system

echo get all objects
kubectl get all --all-namespaces




