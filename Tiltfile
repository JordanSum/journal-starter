k8s_yaml([
    # Local secrets (not committed to git)
    'k8s/local/secrets.yaml',
    'k8s/local/postgres.yaml',
    'k8s/local/db-setup.yaml',
    # Local deployments (no CSI mounts)
    'k8s/local/deployment.yaml',
    'k8s/local/grafana-deployment.yaml',
    # Shared resources
    'k8s/service.yaml',
    'k8s/monitoring/namespace.yaml',
    'k8s/monitoring/prometheus-rbac.yaml',
    'k8s/monitoring/prometheus-config.yaml',
    'k8s/monitoring/prometheus-deployment.yaml',
    'k8s/monitoring/grafana-datasources.yaml',
    'k8s/monitoring/grafana-dashboard-provider.yaml',
    'k8s/monitoring/grafana-dashboard.yaml',
])

k8s_resource('journal-api', port_forwards=8000)
k8s_resource('postgres', port_forwards=5432)

docker_build('journal-api', '.')

