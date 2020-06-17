#!/bin/bash
echo This script will configure ElasticSearch ECK stack Kubernetes.

bash ./setupwin10K8sOnWsl2.sh

if not [[ $(kubectl cluster-info | grep "running") ]]; then
	echo "ERROR: Kubectl CLI is not running!"
	exit 1
else
	echo "Good: Kubectl CLI is running"
	echo "Setup Elastic Cloud"
	echo Download ECK operator
	kubectl apply -f https://download.elastic.co/downloads/eck/1.0.0/all-in-one.yaml
	sleep 2
	kubectl wait --for=condition=ready pod -l control-plane=elastic-operator --namespace=elastic-system
	echo Create Elastic Search container
	#https://raw.githubusercontent.com/elastic/cloud-on-k8s/master/config/samples/elasticsearch/elasticsearch.yaml
	kubectl apply -f configelastic.yaml
	echo Create Kibana container
	#https://raw.githubusercontent.com/elastic/cloud-on-k8s/master/config/samples/kibana/kibana_es.yaml
	kubectl apply -f configkibana.yaml
  echo "Printing debug info"
	kubectl get all --all-namespaces
  echo "wait for containers to be created"
	#sleep 20
  #	kubectl get pods
  #echo "Printing debug info"
  #kubectl get all --all-namespaces
	#echo "Use kubectl get pods to check that es and kb pods are running."
	#echo "https://localhost:30218/"
	#echo "https://localhost:31586/"
	#https://localhost:32520/app/kibana#/home/tutorial_directory/sampleData?_g=()
	#read -p "Press ENTER to continue ..."
	#elasticsearch.elasticsearch.k8s.elastic.co/elasticsearch

	until kubectl wait --for=condition=ready pod -l common.k8s.elastic.co/type=elasticsearch -n=elastic-system;
	do sleep 2; done
	until kubectl wait --for=condition=ready pod -l common.k8s.elastic.co/type=kibana -n=elastic-system
	do sleep 2; done

	kubectl get all --all-namespaces

	echo Get Elasticsearch password
	ESPASSWRD=$(kubectl get secret elasticsearch-es-elastic-user -n=elastic-system -o=jsonpath='{.data.elastic}' | base64 -d)
	echo $ESPASSWRD

	echo "Please manually update the filebeat.yaml and metricbeat.yaml file with the password"
	read -p "Press ENTER to continue ..."

	#echo setup dns debug tools
	#kubectl apply -f dnsutils.yaml
	#kubectl exec -ti dnsutils -- sh


	echo "Create filebeat"
	kubectl apply -f configfilebeat.yaml
	until kubectl wait pod -n=kube-system --for=condition=ready -l k8s-app=filebeat;
	do sleep 2; done
	kubectl logs daemonset.apps/filebeat -n=kube-system #--follow
	read -p "Press ENTER to resume ..."


	echo "Install kube-state-metrics if not available."
	#https://github.com/elastic/beats/blob/master/deploy/kubernetes/metricbeat-kubernetes.yaml
	echo "WARNING: This will upgrade kube-state-metrics to the latest version and may break your setup if you're running old stuff!"
	read -p "Press ENTER to resume ..."
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/kube-state-metrics/master/examples/standard/cluster-role-binding.yaml
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/kube-state-metrics/master/examples/standard/cluster-role.yaml
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/kube-state-metrics/master/examples/standard/deployment.yaml
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/kube-state-metrics/master/examples/standard/service-account.yaml
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/kube-state-metrics/master/examples/standard/service.yaml
	until kubectl wait pod --namespace=kube-system --for=condition=ready -l app.kubernetes.io/name=kube-state-metrics;
	do sleep 2; done

	echo "Create metricbeat"
	kubectl apply -f configmetricbeat.yaml
	until kubectl wait pod --namespace=kube-system --for=condition=ready -l k8s-app=metricbeat;
	do sleep 2; done
	kubectl logs daemonset.apps/metricbeat --namespace=kube-system

	echo "List all objects: kubectl get all --all-namespaces"
	kubectl get all --all-namespaces

fi
