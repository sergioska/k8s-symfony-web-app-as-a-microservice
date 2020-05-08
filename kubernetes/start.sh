#!/usr/bin/env bash

minikube start
eval $(minikube docker-env)

kubectl delete deployment,service,rs --all

kubectl apply -f configMap.yaml
kubectl apply -f volumes -f pods -f services

helm install stable-mysql \
  --set mysqlRootPassword=root,mysqlUser=root,mysqlPassword=root,mysqlDatabase=sylius_dev,persistence.existingClaim=mysql-pvc \
  stable/mysql

kubectl apply -f services/nginx.yaml

