#!/bin/bash
echo This script will configure ElasticSearch ECK stack on Windows 10 with WSL 2.

bash ./setupWSL2-K8S.sh

echo Setup ECK
echo Download ECK operator
kubectl apply -f https://download.elastic.co/downloads/eck/1.0.0/all-in-one.yaml
echo Create Elastic Search container
kubectl apply -f configElastic.yaml
echo Create Kibana container
kubectl apply -f configkibana.yaml

kubectl wait --for=condition=ready pod -l common.k8s.elastic.co/type=kibana
kubectl wait --for=condition=ready pod -l common.k8s.elastic.co/type=elasticsearch
kubectl get pods
echo "Use kubectl get pods to check that es and kb pods are running."
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
kubectl wait pod --namespace=kube-system --for=condition=ready -l k8s-app=filebeat
kubectl logs daemonset.apps/filebeat --namespace=kube-system #--follow
read -p "Press any key to resume ..."

echo Create metricbeat
kubectl apply -f configMetricbeat.yaml
kubectl wait pod --namespace=kube-system --for=condition=ready -l k8s-app=metricbeat
kubectl logs daemonset.apps/metricbeat --namespace=kube-system

echo get all objects
kubectl get all --all-namespaces




