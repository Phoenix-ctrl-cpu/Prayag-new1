# Adding Main and Prod Clusters to ArgoCD

This guide will help you add your main and prod clusters to your existing ArgoCD installation on the dev cluster.

## Prerequisites

- ArgoCD installed and running on dev cluster
- Access to main and prod cluster kubeconfig files or contexts
- kubectl and ArgoCD CLI installed (already done)

## Step-by-Step Instructions

### 1. Verify ArgoCD Installation

First, let's verify that ArgoCD is running on your dev cluster:

```bash
kubectl get pods -n argocd
```

You should see pods like:
- argocd-server
- argocd-application-controller
- argocd-dex-server
- argocd-redis
- argocd-repo-server

### 2. Get ArgoCD Admin Password

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### 3. Connect to ArgoCD

Set up port forwarding and login:

```bash
# Port forward ArgoCD server
kubectl port-forward svc/argocd-server -n argocd 8080:443 &

# Login to ArgoCD (replace <password> with the password from step 2)
argocd login localhost:8080 --username admin --password <password> --insecure
```

### 4. Add Clusters to ArgoCD

You have several options to add your clusters:

#### Option A: Using Kubeconfig Files

If you have kubeconfig files for your main and prod clusters:

```bash
# Add main cluster
argocd cluster add main --kubeconfig /path/to/main-kubeconfig --server https://main-cluster-server:6443

# Add prod cluster
argocd cluster add prod --kubeconfig /path/to/prod-kubeconfig --server https://prod-cluster-server:6443
```

#### Option B: Using Kubectl Contexts

If you have kubectl contexts configured:

```bash
# Switch to main cluster context
kubectl config use-context main-cluster-context

# Add main cluster
argocd cluster add main

# Switch to prod cluster context
kubectl config use-context prod-cluster-context

# Add prod cluster
argocd cluster add prod
```

#### Option C: Using the Provided Scripts

Run the setup script:

```bash
./add-specific-clusters.sh
```

### 5. Verify Clusters

List all clusters in ArgoCD:

```bash
argocd cluster list
```

You should see:
- dev (in-cluster)
- main
- prod

### 6. Test Cluster Access

Test that ArgoCD can access your clusters:

```bash
# Test main cluster
argocd cluster get main

# Test prod cluster
argocd cluster get prod
```

## Troubleshooting

### Common Issues

1. **Cluster not accessible**: Ensure the cluster server URL is correct and accessible
2. **Authentication failed**: Check that the kubeconfig file has valid credentials
3. **Permission denied**: Ensure the service account has proper RBAC permissions

### RBAC Permissions

For ArgoCD to manage applications on your clusters, the service account needs these permissions:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: argocd-manager
rules:
- apiGroups:
  - '*'
  resources:
  - '*'
  verbs:
  - '*'
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: argocd-manager
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: argocd-manager
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: argocd-manager
subjects:
- kind: ServiceAccount
  name: argocd-manager
  namespace: kube-system
```

## Next Steps

After successfully adding your clusters:

1. Create applications that can be deployed to different clusters
2. Set up cluster-specific configurations
3. Configure cluster-specific policies and constraints
4. Set up monitoring and logging for multi-cluster deployments

## Useful Commands

```bash
# List all clusters
argocd cluster list

# Get cluster details
argocd cluster get <cluster-name>

# Remove a cluster
argocd cluster rm <cluster-name>

# Get cluster credentials
argocd cluster get-credentials <cluster-name>

# List applications
argocd app list

# Create an application
argocd app create <app-name> --repo <repo-url> --path <path> --dest-server <cluster-url> --dest-namespace <namespace>
```

## Security Considerations

1. **Network Security**: Ensure proper network policies between clusters
2. **RBAC**: Use least privilege principle for service accounts
3. **Secrets Management**: Use external secret management systems
4. **Audit Logging**: Enable audit logging for cluster operations
5. **Encryption**: Ensure data in transit and at rest is encrypted