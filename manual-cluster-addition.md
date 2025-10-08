# Manual Cluster Addition to ArgoCD

Since the automated scripts may have limitations, here's a manual step-by-step guide to add your main and prod clusters to ArgoCD.

## Prerequisites

1. ArgoCD installed and running on dev cluster
2. Access to main and prod cluster kubeconfig files
3. kubectl and ArgoCD CLI installed

## Step 1: Verify ArgoCD is Running

```bash
kubectl get pods -n argocd
```

You should see pods like:
- argocd-server
- argocd-application-controller
- argocd-dex-server
- argocd-redis
- argocd-repo-server

## Step 2: Get ArgoCD Admin Password

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

Copy this password - you'll need it to login to ArgoCD.

## Step 3: Setup Port Forwarding

In one terminal, run:
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Keep this terminal running.

## Step 4: Login to ArgoCD

In another terminal, run:
```bash
argocd login localhost:8080 --username admin --password <your-password> --insecure
```

Replace `<your-password>` with the password from Step 2.

## Step 5: Add Main Cluster

### Option A: Using Kubeconfig File

If you have a kubeconfig file for your main cluster:

```bash
argocd cluster add main --kubeconfig /path/to/main-kubeconfig --server https://main-cluster-server:6443
```

### Option B: Using Kubectl Context

If you have a kubectl context for your main cluster:

```bash
# Switch to main cluster context
kubectl config use-context main-cluster-context

# Add main cluster
argocd cluster add main
```

## Step 6: Add Prod Cluster

### Option A: Using Kubeconfig File

If you have a kubeconfig file for your prod cluster:

```bash
argocd cluster add prod --kubeconfig /path/to/prod-kubeconfig --server https://prod-cluster-server:6443
```

### Option B: Using Kubectl Context

If you have a kubectl context for your prod cluster:

```bash
# Switch to prod cluster context
kubectl config use-context prod-cluster-context

# Add prod cluster
argocd cluster add prod
```

## Step 7: Verify Clusters

List all clusters in ArgoCD:

```bash
argocd cluster list
```

You should see:
- dev (in-cluster)
- main
- prod

## Step 8: Test Cluster Access

Test that ArgoCD can access your clusters:

```bash
# Test main cluster
argocd cluster get main

# Test prod cluster
argocd cluster get prod
```

## Troubleshooting

### Common Issues

1. **"cluster not accessible"**: Check that the cluster server URL is correct and accessible
2. **"authentication failed"**: Verify the kubeconfig file has valid credentials
3. **"permission denied"**: Ensure the service account has proper RBAC permissions

### RBAC Setup on Target Clusters

For ArgoCD to manage applications on your clusters, you need to create a service account with proper permissions on each target cluster (main and prod).

Apply this configuration to your main and prod clusters:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: argocd-manager
  namespace: kube-system

---
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

# List applications
argocd app list

# Create an application
argocd app create <app-name> --repo <repo-url> --path <path> --dest-server <cluster-url> --dest-namespace <namespace>
```