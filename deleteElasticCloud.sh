#!/bin/bash
echo This script will delete all ECK pods from kubernetes, this WILL break any Elastic Stack components you have, regardless of how you installed them.
read -p "Press ^C to stop or any key to continue ..."


bash ./setupWSL2-K8S.sh

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
