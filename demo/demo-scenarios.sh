#!/bin/bash

# ArgoCD Demo Scenarios Script
# This script demonstrates ArgoCD capabilities and pros/cons

set -e

echo "🎭 Starting ArgoCD Demo Scenarios..."

# Switch to management cluster
kubectl config use-context argocd-mgmt

# Get ArgoCD server IP
ARGOCD_SERVER=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
if [ -z "$ARGOCD_SERVER" ]; then
    ARGOCD_SERVER="localhost"
fi

# Login to ArgoCD
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
argocd login $ARGOCD_SERVER --username admin --password $ARGOCD_PASSWORD --insecure

# Demo 1: GitOps - Automatic Sync
demo_gitops_sync() {
    echo "🎯 Demo 1: GitOps - Automatic Sync"
    echo "=================================="
    echo ""
    echo "✅ PROS:"
    echo "- Single source of truth (Git repository)"
    echo "- Automatic synchronization with Git changes"
    echo "- Audit trail of all changes"
    echo "- Rollback capability"
    echo ""
    echo "❌ CONS:"
    echo "- Requires Git knowledge"
    echo "- Can be complex for simple deployments"
    echo "- Git repository becomes critical dependency"
    echo ""
    echo "🔄 Demonstrating automatic sync..."
    
    # Show current sync status
    echo "Current sync status:"
    argocd app list
    
    echo "Press Enter to continue..."
    read
}

# Demo 2: Multi-Environment Management
demo_multi_environment() {
    echo "🎯 Demo 2: Multi-Environment Management"
    echo "======================================"
    echo ""
    echo "✅ PROS:"
    echo "- Single dashboard for all environments"
    echo "- Consistent deployment process"
    echo "- Environment-specific configurations"
    echo "- Easy promotion between environments"
    echo ""
    echo "❌ CONS:"
    echo "- Complex setup initially"
    echo "- Requires cluster management"
    echo "- Can be overwhelming for small teams"
    echo ""
    echo "🔄 Showing multi-environment setup..."
    
    # Show all environments
    echo "Available environments:"
    argocd app list --output table
    
    echo "Environment details:"
    for env in dev qa prod; do
        echo "--- $env Environment ---"
        argocd app get prayag-app-$env --output table
        echo ""
    done
    
    echo "Press Enter to continue..."
    read
}

# Demo 3: Health Monitoring
demo_health_monitoring() {
    echo "🎯 Demo 3: Health Monitoring"
    echo "============================"
    echo ""
    echo "✅ PROS:"
    echo "- Real-time health status"
    echo "- Visual health indicators"
    echo "- Automatic health checks"
    echo "- Detailed health information"
    echo ""
    echo "❌ CONS:"
    echo "- Limited to Kubernetes health checks"
    echo "- May not catch application-level issues"
    echo "- Requires proper health check configuration"
    echo ""
    echo "🔄 Demonstrating health monitoring..."
    
    # Show health status
    echo "Application health status:"
    for env in dev qa prod; do
        echo "--- $env Health ---"
        argocd app get prayag-app-$env --output json | jq '.status.health'
        echo ""
    done
    
    echo "Press Enter to continue..."
    read
}

# Demo 4: Rollback Capability
demo_rollback() {
    echo "🎯 Demo 4: Rollback Capability"
    echo "=============================="
    echo ""
    echo "✅ PROS:"
    echo "- One-click rollback"
    echo "- Rollback to any previous version"
    echo "- Safe rollback process"
    echo "- History tracking"
    echo ""
    echo "❌ CONS:"
    echo "- Requires proper versioning"
    echo "- May not work if database schema changed"
    echo "- Rollback can be complex for stateful applications"
    echo ""
    echo "🔄 Demonstrating rollback capability..."
    
    # Show application history
    echo "Application deployment history:"
    for env in dev qa prod; do
        echo "--- $env History ---"
        argocd app history prayag-app-$env
        echo ""
    done
    
    echo "Press Enter to continue..."
    read
}

# Demo 5: Sync Policies
demo_sync_policies() {
    echo "🎯 Demo 5: Sync Policies"
    echo "========================"
    echo ""
    echo "✅ PROS:"
    echo "- Automated sync for dev/qa"
    echo "- Manual approval for production"
    echo "- Self-healing capabilities"
    echo "- Prune orphaned resources"
    echo ""
    echo "❌ CONS:"
    echo "- Can be dangerous if misconfigured"
    echo "- Automated sync might cause issues"
    echo "- Requires careful policy design"
    echo ""
    echo "🔄 Demonstrating sync policies..."
    
    # Show sync policies
    echo "Sync policies:"
    for env in dev qa prod; do
        echo "--- $env Sync Policy ---"
        argocd app get prayag-app-$env --output json | jq '.spec.syncPolicy'
        echo ""
    done
    
    echo "Press Enter to continue..."
    read
}

# Demo 6: Resource Management
demo_resource_management() {
    echo "🎯 Demo 6: Resource Management"
    echo "=============================="
    echo ""
    echo "✅ PROS:"
    echo "- Visual resource tree"
    echo "- Resource status monitoring"
    echo "- Easy resource discovery"
    echo "- Resource relationship visualization"
    echo ""
    echo "❌ CONS:"
    echo "- Can be overwhelming with many resources"
    echo "- Limited resource editing capabilities"
    echo "- Requires Kubernetes knowledge"
    echo ""
    echo "🔄 Demonstrating resource management..."
    
    # Show resource tree
    echo "Resource tree for dev environment:"
    argocd app resources prayag-app-dev
    
    echo "Press Enter to continue..."
    read
}

# Demo 7: Performance and Scalability
demo_performance() {
    echo "🎯 Demo 7: Performance and Scalability"
    echo "====================================="
    echo ""
    echo "✅ PROS:"
    echo "- Handles multiple clusters efficiently"
    echo "- Scales with cluster size"
    echo "- Efficient resource utilization"
    echo "- Good performance for most use cases"
    echo ""
    echo "❌ CONS:"
    echo "- Can be slow with many applications"
    echo "- Memory usage can be high"
    echo "- Requires proper resource allocation"
    echo "- May struggle with very large clusters"
    echo ""
    echo "🔄 Demonstrating performance..."
    
    # Show cluster performance
    echo "Cluster resource usage:"
    kubectl top nodes
    echo ""
    echo "ArgoCD resource usage:"
    kubectl top pods -n argocd
    
    echo "Press Enter to continue..."
    read
}

# Demo 8: Security and Access Control
demo_security() {
    echo "🎯 Demo 8: Security and Access Control"
    echo "======================================"
    echo ""
    echo "✅ PROS:"
    echo "- RBAC integration"
    echo "- Project-based access control"
    echo "- Repository access control"
    echo "- Audit logging"
    echo ""
    echo "❌ CONS:"
    echo "- Complex security setup"
    echo "- Requires proper RBAC configuration"
    echo "- Can be difficult to troubleshoot"
    echo "- Limited fine-grained permissions"
    echo ""
    echo "🔄 Demonstrating security features..."
    
    # Show security configuration
    echo "ArgoCD security configuration:"
    kubectl get roles,rolebindings,clusterroles,clusterrolebindings -n argocd
    
    echo "Press Enter to continue..."
    read
}

# Main demo execution
main() {
    echo "🎭 ArgoCD Demo Scenarios"
    echo "========================"
    echo ""
    echo "This demo will showcase ArgoCD capabilities and discuss pros/cons"
    echo "Press Enter to start..."
    read
    
    demo_gitops_sync
    demo_multi_environment
    demo_health_monitoring
    demo_rollback
    demo_sync_policies
    demo_resource_management
    demo_performance
    demo_security
    
    echo "🎉 Demo completed!"
    echo ""
    echo "📋 Summary:"
    echo "ArgoCD is a powerful GitOps tool that provides:"
    echo "- Multi-cluster management"
    echo "- Automated deployments"
    echo "- Health monitoring"
    echo "- Rollback capabilities"
    echo "- Security controls"
    echo ""
    echo "However, it also has some limitations:"
    echo "- Complex initial setup"
    echo "- Requires Git and Kubernetes knowledge"
    echo "- Can be overwhelming for small teams"
    echo "- Performance issues with large deployments"
    echo ""
    echo "🌐 Access ArgoCD UI at: https://localhost:8080"
}

main "$@"