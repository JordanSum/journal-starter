# Runbook: Credential Leak Response

## Overview
This runbook outlines the steps to take when credentials are leaked or suspected to be compromised.

---

## 1. Immediate Actions (First 15 Minutes)

### Identify the Scope
- [ ] Determine which credentials were leaked
- [ ] Identify where the leak occurred (git commit, logs, public repo, etc.)
- [ ] Estimate the exposure window (how long were credentials visible?)

### Revoke Immediately
- [ ] Disable or revoke the compromised credentials
- [ ] Do NOT wait to investigate first—contain the breach immediately

---

## 2. Rotate Credentials

### PostgreSQL Database Password
1. Generate a new secure password
2. Update `infra/terraform.tfvars` with the new password
3. Run `terraform apply` to update Azure resources
4. Update Kubernetes secret:
   ```bash
   kubectl delete secret journal-secrets -n default
   kubectl create secret generic journal-secrets \
     --from-literal=DATABASE_URL="postgresql://user:NEW_PASSWORD@host:5432/db"
   ```
5. Restart application pods: `kubectl rollout restart deployment/journal-api`

### GitHub Secrets
1. Go to Repository → Settings → Secrets and variables → Actions
2. Update each compromised secret with new values
3. Re-run any workflows that need the new credentials

### Kubernetes Secrets
1. Regenerate the secret values
2. Update `k8s/secrets.yaml` (ensure it's not committed to git)
3. Apply: `kubectl apply -f k8s/secrets.yaml`
4. Restart affected deployments

### Docker Registry Tokens
1. Regenerate access tokens in your container registry
2. Update CI/CD pipeline secrets
3. Update local Docker login if needed

---

## 3. Check for Unauthorized Access

### Azure Activity Logs
```bash
az monitor activity-log list --resource-group <rg-name> --start-time <leak-start> --end-time <now>
```

### PostgreSQL Audit
- Review connection logs for unknown IPs
- Check for unexpected queries or data exports
- Look for new users or permission changes:
  ```sql
  SELECT * FROM pg_roles WHERE rolcreatedtime > '<leak-start-time>';
  ```

### Application Logs
- Search for unusual API patterns
- Check for bulk data access
- Review authentication failures and successes

### Git History
- Check for unauthorized commits
- Review any new deploy keys or webhooks
- Audit repository access logs

---

## 4. Notify Stakeholders

### Internal Notification (Within 1 Hour)
- [ ] Security team / Security lead
- [ ] Engineering manager
- [ ] DevOps / Infrastructure team

### Management Notification (Within 4 Hours)
- [ ] CTO / Technical leadership
- [ ] Legal team (if user data may be affected)

### External Notification (If Required)
- [ ] Affected users (if their data was accessed)
- [ ] Compliance/regulatory bodies (if applicable)

### Communication Template
```
SECURITY INCIDENT: Credential Exposure

Time Detected: [TIMESTAMP]
Credentials Affected: [LIST]
Exposure Window: [START] to [END]
Current Status: [Contained/Investigating/Resolved]
Actions Taken: [SUMMARY]
Next Steps: [PLAN]
```

---

## 5. Post-Incident Review

### Within 48 Hours
- [ ] Document timeline of events
- [ ] Identify root cause of the leak
- [ ] Assess actual impact (was data accessed?)

### Preventive Measures
- [ ] Enable GitHub secret scanning
- [ ] Add pre-commit hooks (e.g., gitleaks, detect-secrets)
- [ ] Review `.gitignore` for sensitive files
- [ ] Audit current secrets management practices
- [ ] Consider using a secrets manager (Azure Key Vault, HashiCorp Vault)

### Document Lessons Learned
- What went wrong?
- What went right in the response?
- What process changes are needed?

---

## Quick Reference: Credentials in This Project

| Credential | Location | Rotation Method |
|------------|----------|-----------------|
| DB Password | `terraform.tfvars`, K8s secrets | Terraform + kubectl |
| GitHub Actions Secrets | GitHub Settings | GitHub UI |
| K8s Secrets | `k8s/secrets.yaml` | kubectl apply |
| Azure Service Principal | Azure AD | az ad sp credential reset |