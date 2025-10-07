# ArgoCD Multi-Cluster Setup

This repository contains scripts and documentation for adding main and prod clusters to your existing ArgoCD installation on the dev cluster.

## Files Overview

- `add-clusters-to-argocd.sh` - Comprehensive script for adding clusters to ArgoCD
- `add-specific-clusters.sh` - Specific script with detailed instructions
- `quick-start.sh` - Quick setup and connection test
- `verify-clusters.sh` - Script to verify cluster connectivity
- `manual-cluster-addition.md` - Step-by-step manual guide
- `ARGOCD_CLUSTER_SETUP.md` - Comprehensive documentation
- `example-cluster-configs.yaml` - Example cluster configurations

## Quick Start

1. **Verify ArgoCD is running:**
   ```bash
   kubectl get pods -n argocd
   ```

2. **Run the quick start script:**
   ```bash
   ./quick-start.sh
   ```

3. **Add your clusters manually:**
   ```bash
   # For main cluster
   argocd cluster add main --kubeconfig /path/to/main-kubeconfig --server https://main-cluster:6443
   
   # For prod cluster
   argocd cluster add prod --kubeconfig /path/to/prod-kubeconfig --server https://prod-cluster:6443
   ```

4. **Verify clusters:**
   ```bash
   ./verify-clusters.sh
   ```

## Prerequisites

- ArgoCD installed and running on dev cluster
- Access to main and prod cluster kubeconfig files or contexts
- kubectl and ArgoCD CLI installed

## Manual Steps

If the automated scripts don't work, follow the manual guide in `manual-cluster-addition.md`.

## Troubleshooting

Common issues and solutions are documented in the individual files. The most common issues are:

1. **Cluster not accessible**: Check cluster server URL and network connectivity
2. **Authentication failed**: Verify kubeconfig file has valid credentials
3. **Permission denied**: Ensure proper RBAC permissions are set up

## Next Steps

After successfully adding your clusters:

1. Create applications that can be deployed to different clusters
2. Set up cluster-specific configurations
3. Configure cluster-specific policies and constraints
4. Set up monitoring and logging for multi-cluster deployments

## Support

If you encounter issues, check the troubleshooting sections in the documentation files or refer to the ArgoCD official documentation.