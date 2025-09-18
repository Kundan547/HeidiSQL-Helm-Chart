# HeidiSQL Helm Chart

A Helm chart for deploying HeidiSQL database management tool in Kubernetes, specifically designed for Azure SQL Database slow query analysis.

## Features

- 🖥️ **Web-based HeidiSQL** - Access HeidiSQL through your browser via NoVNC
- 🔗 **Pre-configured Azure SQL** - Ready-to-use connection setup
- 📊 **Built-in Query Analysis** - Pre-loaded slow query and performance analysis scripts
- 🔒 **Secure Access** - VNC password protection and optional ingress TLS
- 💾 **Persistent Storage** - Optional persistent volumes for settings and data
- 🚀 **Production Ready** - Resource limits, probes, and security contexts

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- Azure SQL Database with appropriate firewall rules

## Installation

### Quick Start

1. **Add the repository** (if published):
```bash
helm repo add heidisql https://your-repo.com/charts
helm repo update
```

2. **Install from local directory**:
```bash
# Clone or create the chart directory
helm install heidisql ./heidisql-chart --namespace heidisql --create-namespace
```

3. **Access the application**:
```bash
kubectl port-forward svc/heidisql 6080:6080 -n heidisql
# Open http://localhost:6080 in your browser
# VNC Password: heidisql123
```

### Custom Installation

1. **Create a custom values file**:
```bash
cat > my-values.yaml << EOF
database:
  server: "myserver.database.windows.net"
  database: "mydatabase"
  username: "myuser"
  password: "mypassword"

ingress:
  enabled: true
  hosts:
    - host: heidisql.mydomain.com
      paths:
        - path: /
          pathType: Prefix

resources:
  limits:
    cpu: 2000m
    memory: 4Gi
  requests:
    cpu: 1000m
    memory: 2Gi
EOF
```

2. **Install with custom values**:
```bash
helm install heidisql ./heidisql-chart -f my-values.yaml -n heidisql --create-namespace
```

## Configuration

### Database Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `database.server` | Azure SQL Server hostname | `your-server.database.windows.net` |
| `database.port` | Database port | `1433` |
| `database.database` | Database name | `your-database-name` |
| `database.username` | Database username | `your-username` |
| `database.password` | Database password | `your-password` |
| `database.existingSecret` | Use existing secret for credentials | `""` |

### VNC Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `vnc.enabled` | Enable VNC server | `true` |
| `vnc.port` | VNC server port | `5901` |
| `vnc.password` | VNC access password | `heidisql123` |
| `vnc.readonly_password` | VNC read-only password | `viewer123` |
| `vnc.resolution` | Screen resolution | `1024x768` |

### Service Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `service.type` | Kubernetes service type | `ClusterIP` |
| `novnc.enabled` | Enable NoVNC web interface | `true` |
| `novnc.port` | NoVNC web port | `6080` |

### Ingress Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ingress.enabled` | Enable ingress | `false` |
| `ingress.className` | Ingress class name | `nginx` |
| `ingress.hosts[0].host` | Hostname for ingress | `heidisql.local` |

### Resource Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `resources.limits.cpu` | CPU limit | `1000m` |
| `resources.limits.memory` | Memory limit | `2Gi` |
| `resources.requests.cpu` | CPU request | `500m` |
| `resources.requests.memory` | Memory request | `1Gi` |

### Persistence Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `persistence.enabled` | Enable persistent storage | `true` |
| `persistence.size` | Storage size | `1Gi` |
| `persistence.storageClass` | Storage class | `""` |
| `persistence.accessMode` | Access mode | `ReadWriteOnce` |

## Usage

### Accessing HeidiSQL

1. **Via Port Forward** (Development):
```bash
kubectl port-forward svc/heidisql 6080:6080 -n heidisql
# Open http://localhost:6080
```

2. **Via Ingress** (Production):
```bash
# Configure ingress in values.yaml first
# Then access via your configured domain
```

3. **Via NodePort** (Testing):
```bash
# Set service.type: NodePort in values.yaml
kubectl get svc heidisql -n heidisql
# Access via http://node-ip:node-port
```

### Using Pre-loaded SQL Scripts

The chart includes ready-to-use SQL scripts for performance analysis:

1. **Open HeidiSQL** in the web interface
2. **Connect to Azure SQL** (connection is pre-configured)
3. **Load scripts** from `/home/heidisql/scripts/`:
   - `slow-queries.sql` - Identify slow queries
   - `performance-analysis.sql` - Comprehensive performance analysis

### Sample Queries

```sql
-- Find top 10 slowest queries
SELECT TOP 10 
    q.query_id,
    SUBSTRING(qt.query_sql_text, 1, 100) as query_preview,
    rs.avg_duration/1000.0 as avg_duration_ms,
    rs.count_executions
FROM sys.query_store_query q
JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
JOIN sys.query_store_runtime_stats rs ON q.query_id = rs.query_id
WHERE rs.avg_duration > 1000000 -- More than 1 second
ORDER BY rs.avg_duration DESC;
```

## Security Considerations

### Production Recommendations

1. **Change default passwords**:
```yaml
vnc:
  password: "your-secure-password"
  readonly_password: "your-readonly-password"
```

2. **Use Kubernetes secrets**:
```bash
kubectl create secret generic heidisql-db-secret \
  --from-literal=username="your-username" \
  --from-literal=password="your-password" \
  -n heidisql
```

```yaml
database:
  existingSecret: "heidisql-db-secret"
  secretKeys:
    username: "username"
    password: "password"
```

3. **Enable TLS for ingress**:
```yaml
ingress:
  tls:
    - secretName: heidisql-tls
      hosts:
        - heidisql.mydomain.com
```

4. **Network policies**:
```yaml
# Create network policy to restrict access
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: heidisql-netpol
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: heidisql
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: allowed-namespace
```

## Troubleshooting

### Common Issues

1. **HeidiSQL doesn't start**:
```bash
# Check VNC server logs
kubectl logs -n heidisql -l app.kubernetes.io/name=heidisql -c vnc-server

# Check HeidiSQL container
kubectl logs -n heidisql -l app.kubernetes.io/name=heidisql -c heidisql
```

2. **Can't connect to Azure SQL**:
   - Verify Azure SQL firewall rules
   - Check if your Kubernetes cluster IPs are allowed
   - Validate connection credentials

3. **Web interface is blank**:
   - Wait 30-60 seconds for VNC server to initialize
   - Check NoVNC container logs
   - Verify screen resolution settings

4. **Performance issues**:
   - Increase resource limits
   - Use faster storage class
   - Optimize VNC resolution

### Debug Commands

```bash
# Check all pods
kubectl get pods -n heidisql -o wide

# Describe pod issues
kubectl describe pod -n heidisql -l app.kubernetes.io/name=heidisql

# Access pod shell
kubectl exec -it -n heidisql deployment/heidisql -c heidisql -- bash

# Test connectivity
kubectl run test-pod --image=busybox -it --rm -- nc -zv heidisql.heidisql.svc.cluster.local 6080
```

## Upgrading

### Upgrade Chart

```bash
# Upgrade to newer version
helm upgrade heidisql ./heidisql-chart -n heidisql

# Upgrade with new values
helm upgrade heidisql ./heidisql-chart -f new-values.yaml -n heidisql
```

### Backup Settings

```bash
# Backup persistent data
kubectl exec -n heidisql deployment/heidisql -c heidisql -- tar czf - /home/heidisql/data > heidisql-backup.tar.gz
```

## Uninstalling

```bash
# Remove the release
helm uninstall heidisql -n heidisql

# Remove persistent volumes (if needed)
kubectl delete pvc -n heidisql -l app.kubernetes.io/name=heidisql

# Remove namespace
kubectl delete namespace heidisql
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with `helm lint` and `helm template`
5. Submit a pull request

## License

This chart is licensed under the Apache 2.0 License.

## Support

For issues and questions:
- Create an issue in the repository
- Check Azure SQL Database documentation
- Consult HeidiSQL official documentation