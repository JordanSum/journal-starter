# Monitoring Setup for Journal API

This guide walks you through setting up Prometheus and Grafana to monitor your Journal API.

## Prerequisites

- AKS cluster running with `kubectl` configured
- Journal API deployed with `/metrics` endpoint enabled

## Step-by-Step Deployment

### Step 1: Deploy the updated Journal API

First, ensure your API includes the `prometheus-fastapi-instrumentator` and push the changes:

```bash
# Install the dependency locally (optional, for testing)
pip install prometheus-fastapi-instrumentator

# Commit and push to trigger CI/CD
git add .
git commit -m "Add Prometheus metrics instrumentation"
git push
```

Wait for the CI/CD pipeline to deploy the updated API.

### Step 2: Verify /metrics endpoint works

```bash
# Test locally or via the LoadBalancer IP
curl http://<YOUR-API-IP>/metrics
```

You should see Prometheus-formatted metrics like:
```
# HELP http_requests_total Total HTTP requests
# TYPE http_requests_total counter
http_requests_total{method="GET",handler="/health",status="200"} 42.0
...
```

### Step 3: Deploy the monitoring namespace and RBAC

```bash
kubectl apply -f k8s/monitoring/namespace.yaml
kubectl apply -f k8s/monitoring/prometheus-rbac.yaml
```

### Step 4: Deploy Prometheus

```bash
kubectl apply -f k8s/monitoring/prometheus-config.yaml
kubectl apply -f k8s/monitoring/prometheus-deployment.yaml
```

Verify Prometheus is running:
```bash
kubectl get pods -n monitoring
# NAME                          READY   STATUS    RESTARTS   AGE
# prometheus-xxxxxxxxxx-xxxxx   1/1     Running   0          1m
```

### Step 5: Deploy Grafana

```bash
kubectl apply -f k8s/monitoring/grafana-datasources.yaml
kubectl apply -f k8s/monitoring/grafana-dashboard-provider.yaml
kubectl apply -f k8s/monitoring/grafana-dashboard.yaml
kubectl apply -f k8s/monitoring/grafana-deployment.yaml
```

### Step 6: Access Grafana

Get the Grafana external IP:
```bash
kubectl get svc grafana -n monitoring
# NAME      TYPE           CLUSTER-IP     EXTERNAL-IP     PORT(S)        AGE
# grafana   LoadBalancer   10.0.xxx.xxx   20.xx.xxx.xxx   80:xxxxx/TCP   1m
```

Open `http://<EXTERNAL-IP>` in your browser.

**Default credentials:**
- Username: `admin`
- Password: `admin`

### Step 7: View the Dashboard

1. Log in to Grafana
2. Click **Dashboards** in the left sidebar
3. Click **Journal API Dashboard**

You should see:
- **Request Rate** - Requests per second by endpoint
- **Request Latency** - p50, p95, p99 latencies
- **Error Rate (5xx)** - Percentage of failed requests
- **Running Pods** - Number of healthy pods
- **Total Requests** - Request count in last 5 minutes
- **Requests by Status Code** - Breakdown by HTTP status

## Quick Deploy (All at Once)

```bash
# Deploy all monitoring components
kubectl apply -f k8s/monitoring/
```

## Verify Prometheus is Scraping

Port-forward to Prometheus UI:
```bash
kubectl port-forward -n monitoring svc/prometheus 9090:9090
```

Open http://localhost:9090 and:
1. Go to **Status** → **Targets**
2. Verify `journal-api` target shows as **UP**

## Troubleshooting

### Prometheus not scraping Journal API

1. Check if pods have correct labels:
   ```bash
   kubectl get pods --show-labels
   ```
   
2. Check Prometheus logs:
   ```bash
   kubectl logs -n monitoring deployment/prometheus
   ```

3. Verify /metrics is accessible from within the cluster:
   ```bash
   kubectl run curl --image=curlimages/curl -it --rm --restart=Never -- \
     curl http://journal-api.default.svc.cluster.local:8000/metrics
   ```

### Grafana shows "No data"

1. Verify Prometheus datasource is configured:
   - Go to **Configuration** → **Data sources**
   - Click **Prometheus** → **Test**
   
2. Check time range - expand to "Last 1 hour"

3. Generate some traffic to create metrics:
   ```bash
   for i in {1..10}; do curl http://<API-IP>/health; done
   ```

## Cleanup

```bash
kubectl delete -f k8s/monitoring/
```
