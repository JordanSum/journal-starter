# Connect GitHub to Azure Steps

## AZURE_CREDENTIALS

After deploying your Azure infrastructure, follow these steps to connect your GitHub to Azure to use GitHub Actions.

Open a terminal and run these commands one by one. Save each output — you'll need them for GitHub.

### Get Azure Subscription ID

```bash
az account show --query id --output tsv
```

Add to the github actions sp

Add AZURE_CREDENTIALS to the GitHub actions web page, will not work through CLI.

```bash
az ad sp create-for-rbac --name "github-actions-sp" \
  --role contributor \
  --scopes /subscriptions/<subscription-id>/resourceGroups/<rg-name> \
  --sdk-auth
```

Save the entire JSON output and put in the AZURE_CREDENTIALS in GitHub Secrets

## Enable Key Vault CSI driver on your AKS cluster.

```bash
az aks enable-addons \
  --addons azure-keyvault-secrets-provider \
  --name <your-aks-cluster-name> \
  --resource-group <rg-name>
```

**Note** If variables and keys are already created in GitHub and you need to run new deployments, update AZURE_CREDENTIALS and AKS_KUBELET_CLIENT_ID

## AKS_KUBELET_CLIENT_ID

```bash
az aks show --resource-group <rg-name> --name aks-name --query "identityProfile.kubeletidentity.clientId" -o tsv
```

## ACR_NAME

The ACR name (not the full login server URL). The workflow uses the Service Principal to authenticate to ACR via `az acr login`.

```bash
az acr show --name <acr-name> --query name -o tsv
```

## ACR_LOGIN_SERVER

```bash
az acr show --name <acr-name> --query loginServer -o tsv
```

Expected output: `<acr-name>.azurecr.io`

## AZURE_RESOURCE_GROUP & AKS_CLUSTER_NAME

Azure Resource Group Name - Refer to infra/main.tf
Azure AKS Cluster Name - Refer to infra/main.tf

## KEYVAULT_NAME

```bash
az keyvault list --resource-group <rg-name> --query "[0].name" -o tsv
```

## AZURE_TENANT_ID

```bash
az account show --query tenantId -o tsv
```

## Add Secrets to GitHub and Azure Key Vault

First install GitHub CLI

```bash
brew install gh
gh auth login
```

Add Secrets, first navigate to your repo root

```bash
cd /path/to/project/root
```

Add variables and keys to GitHub Actions

```bash
gh secret set ACR_NAME --body "<acr-name>"
gh secret set ACR_LOGIN_SERVER --body "<acr-name>.azurecr.io"
gh secret set KEYVAULT_NAME --body "<keyvault-name>"
gh secret set AZURE_TENANT_ID --body "<tenant-id>"
gh secret set AZURE_RESOURCE_GROUP --body "<rg-name>"
gh secret set AKS_CLUSTER_NAME --body "<aks-cluster-name>"
gh secret set AKS_KUBELET_CLIENT_ID --body "<kubelet-client-id>"
```

> **Note:** ACR authentication uses the Service Principal (AZURE_CREDENTIALS) instead of ACR admin credentials. This is more secure and avoids storing additional passwords.

Add variable and keys to Key Vault

```bash
az keyvault secret set --vault-name <key-vault-name> --name AZURE-OPENAI-API-KEY --value "<api-key>"
az keyvault secret set --vault-name <key-vault-name> --name AZURE-OPENAI-ENDPOINT --value "<endpoint-url>"
az keyvault secret set --vault-name <key-vault-name> --name AZURE-OPENAI-DEPLOYMENT --value "<deployment-name>"
az keyvault secret set --vault-name <key-vault-name> --name DATABASE-URL --value "<database-url>"
az keyvault secret set --vault-name <key-vault-name> --name GRAFANA-ADMIN-USER --value "<username>"
az keyvault secret set --vault-name <key-vault-name> --name GRAFANA-ADMIN-PASSWORD --value "<grafana-password>"
```

## Verify Secrets Are Set

### GitHub

```bash
# List all secrets in GitHub
gh secret list
```

### Azure Key Vault

```bash
# List all secrets in the vault
az keyvault secret list --vault-name <your-keyvault-name> --output table
```

## Troubleshot

Error: Service principal already exists
→ Delete and recreate:

```bash
az ad sp delete --id "github-actions-sp"
az ad sp create-for-rbac --name "github-actions-sp" ...
```