# Kubernetes Deployment

This directory contains Kubernetes manifests for deploying the Journal API to Azure Kubernetes Service (AKS).

## Overview

| File                       | Description                                                    |
|----------------------------|----------------------------------------------------------------|
| `deployment.yaml`          | Journal API deployment with 2 replicas and health probes       |
| `service.yaml`             | LoadBalancer service exposing the API on port 80               |
| `secrets.yaml`             | SecretProviderClass for Azure Key Vault integration            |
| `ingress.yaml`             | Ingress rules for HTTPS traffic with TLS termination           |
| `cluster-issuer.yaml`      | Let's Encrypt ClusterIssuer for automatic TLS certificates     |
| `helm/`                    | Helm values for NGINX Ingress Controller and cert-manager      |
| `monitoring/`              | Prometheus and Grafana monitoring stack                        |

## Prerequisites

- Azure CLI installed and authenticated (`az login`)
- kubectl installed
- Helm 3 installed
- AKS cluster deployed (see `infra/` directory)
- Azure Container Registry (ACR) with your image pushed
- Azure Key Vault with secrets configured

## Quick Start

### 1. Connect to AKS

```bash
az aks get-credentials --resource-group <rg-name> --name <aks-cluster-name> --overwrite-existing
```

### 2. Set Environment Variables

```bash
export KEYVAULT_NAME="<your-keyvault-name>"
export AZURE_TENANT_ID="<your-tenant-id>"
export AKS_KUBELET_CLIENT_ID="<kubelet-client-id>"
```

To get the kubelet client ID:
```bash
az aks show --resource-group <rg-name> --name <aks-cluster-name> \
  --query "identityProfile.kubeletidentity.clientId" -o tsv
```

### 3. Deploy Core Resources

```bash
# Deploy secrets provider
envsubst < k8s/secrets.yaml | kubectl apply -f -

# Deploy the API
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

### 4. Deploy Ingress (Optional - for HTTPS)

See [helm/README.md](helm/README.md) for NGINX Ingress and cert-manager setup.

```bash
# After Helm charts are installed
kubectl apply -f k8s/cluster-issuer.yaml
kubectl apply -f k8s/ingress.yaml
```

### 5. Deploy Monitoring (Optional)

See [monitoring/README.md](monitoring/README.md) for Prometheus and Grafana setup.

```bash
kubectl apply -f k8s/monitoring/
```

## Verify Deployment

```bash
# Check pod status
kubectl get pods

# Check service external IP
kubectl get svc journal-api

# View logs
kubectl logs -l app=journal-api --tail=100

# Describe deployment
kubectl describe deployment journal-api
```

## Configuration

### Environment Variables

The API expects these secrets from Azure Key Vault:

| Secret Name              | Description                          |
|--------------------------|--------------------------------------|
| `DATABASE-URL`           | PostgreSQL connection string         |
| `AZURE-OPENAI-API-KEY`   | Azure OpenAI API key                 |
| `AZURE-OPENAI-ENDPOINT`  | Azure OpenAI endpoint URL            |
| `AZURE-OPENAI-DEPLOYMENT`| Azure OpenAI deployment name         |

### Resource Limits

Default resource configuration in `deployment.yaml`:

| Resource | Request | Limit  |
|----------|---------|--------|
| CPU      | 100m    | 500m   |
| Memory   | 128Mi   | 512Mi  |

Adjust these based on your workload requirements.

### Replicas

Default: 2 replicas for high availability. Modify `spec.replicas` in `deployment.yaml` as needed.

## Updating the Deployment

### Update Image

```bash
kubectl set image deployment/journal-api \
  journal-api=<acr-name>.azurecr.io/journal-api:<new-tag>
```

### Rolling Restart

```bash
kubectl rollout restart deployment/journal-api
```

### View Rollout Status

```bash
kubectl rollout status deployment/journal-api
```

## Troubleshooting

### Pods not starting

1. Check pod events:
   ```bash
   kubectl describe pod -l app=journal-api
   ```

2. Check logs:
   ```bash
   kubectl logs -l app=journal-api --previous
   ```

3. Verify secrets are mounted:
   ```bash
   kubectl exec -it <pod-name> -- ls /mnt/secrets-store
   ```

### ImagePullBackOff

1. Verify ACR credentials:
   ```bash
   kubectl get secrets
   ```

2. Check AKS has ACR pull permissions:
   ```bash
   az aks check-acr --name <aks-name> --resource-group <rg-name> \
     --acr <acr-name>.azurecr.io
   ```

### Service has no External IP

1. Check service status:
   ```bash
   kubectl describe svc journal-api
   ```

2. Verify AKS has a load balancer:
   ```bash
   kubectl get svc -A | grep LoadBalancer
   ```

### Secrets not mounting

1. Verify SecretProviderClass:
   ```bash
   kubectl describe secretproviderclass azure-keyvault-secrets
   ```

2. Check Key Vault CSI driver is enabled:
   ```bash
   az aks show --resource-group <rg-name> --name <aks-name> \
     --query "addonProfiles.azureKeyvaultSecretsProvider"
   ```

3. Verify managed identity has Key Vault access:
   ```bash
   az keyvault show --name <keyvault-name> --query "properties.accessPolicies"
   ```

## Cleanup

```bash
# Delete all resources
kubectl delete -f k8s/
kubectl delete -f k8s/monitoring/

# Or delete specific resources
kubectl delete deployment journal-api
kubectl delete svc journal-api
```

## Related Documentation

- [GitHub-Azure Connection](../docs/github-azure-connection.md) - Set up GitHub Actions CI/CD
- [Helm Charts](helm/README.md) - NGINX Ingress and cert-manager
- [Monitoring](monitoring/README.md) - Prometheus and Grafana setup
- [Infrastructure](../infra/) - Terraform for AKS, ACR, Key Vault
