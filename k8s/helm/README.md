# Helm Chart Dependencies

This directory contains Helm values files for cluster infrastructure components.

## Prerequisites

```bash
# Add Helm repositories
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add jetstack https://charts.jetstack.io
helm repo update
```

## Installation

### 1. NGINX Ingress Controller

```bash
helm install ingress-nginx ingress-nginx/ingress-nginx \
  -n ingress-nginx --create-namespace \
  -f k8s/helm/ingress-nginx-values.yaml
```

### 2. cert-manager

```bash
helm install cert-manager jetstack/cert-manager \
  -n cert-manager --create-namespace \
  -f k8s/helm/cert-manager-values.yaml
```

### 3. ClusterIssuer and Ingress

```bash
kubectl apply -f k8s/cluster-issuer.yaml
kubectl apply -f k8s/ingress.yaml
```

## Upgrade

```bash
helm upgrade ingress-nginx ingress-nginx/ingress-nginx \
  -n ingress-nginx -f k8s/helm/ingress-nginx-values.yaml

helm upgrade cert-manager jetstack/cert-manager \
  -n cert-manager -f k8s/helm/cert-manager-values.yaml
```

## Uninstall

```bash
helm uninstall ingress-nginx -n ingress-nginx
helm uninstall cert-manager -n cert-manager
kubectl delete namespace ingress-nginx cert-manager
```
