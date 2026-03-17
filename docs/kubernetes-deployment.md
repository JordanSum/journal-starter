# 1. Connect to AKS

```bash
az aks get-credentials --resource-group <rg-name> --name <aks-name> --overwrite-existing
```

# 2. Create monitoring namespace

```bash
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
```

# 3. Deploy main app resources (substitute placeholders first)

```bash
export KEYVAULT_NAME="<your-keyvault-name>"
export AZURE_TENANT_ID="<your-tenant-id>"

envsubst < k8s/secrets.yaml | kubectl apply -f -
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

# 4. Deploy monitoring resources

```bash
envsubst < k8s/monitoring/secrets.yaml | kubectl apply -f -
kubectl apply -f k8s/monitoring/
```

# 5. Deploy cert-manager and nginx resources

```bash
helm install ingress-nginx ingress-nginx/ingress-nginx -n ingress-nginx --create-namespace -f k8s/helm/ingress-nginx-values.yaml
helm install cert-manager jetstack/cert-manager -n cert-manager --create-namespace -f k8s/helm/cert-manager-values.yaml
kubectl apply -f k8s/cluster-issuer.yaml
kubectl apply -f k8s/ingress.yaml
```

Verify deployment:

```bash
kubectl get pods
kubectl get pods -n monitoring
kubectl get svc
kubectl get svc -n monitoring
```