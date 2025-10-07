#!/bin/bash

# GitOps Repository Setup Script
# This script sets up the GitOps repository structure and ArgoCD applications

set -e

echo "📁 Setting up GitOps repository structure..."

# Create GitOps directory structure
mkdir -p gitops/{base,overlays/{dev,qa,prod}}
mkdir -p gitops/applications
mkdir -p gitops/projects

# Create base Kubernetes manifests
create_base_manifests() {
    echo "📝 Creating base Kubernetes manifests..."
    
    cat > gitops/base/namespace.yaml << EOF
apiVersion: v1
kind: Namespace
metadata:
  name: prayag-app
  labels:
    name: prayag-app
    environment: \${ENVIRONMENT}
EOF

    cat > gitops/base/configmap.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: prayag-app-config
  namespace: prayag-app
data:
  APP_NAME: "prayag-new1-pipeline"
  APP_VERSION: "\${APP_VERSION}"
  ENVIRONMENT: "\${ENVIRONMENT}"
  TOMCAT_PORT: "8080"
EOF

    cat > gitops/base/deployment.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prayag-app-deployment
  namespace: prayag-app
  labels:
    app: prayag-app
    environment: \${ENVIRONMENT}
spec:
  replicas: \${REPLICAS}
  selector:
    matchLabels:
      app: prayag-app
  template:
    metadata:
      labels:
        app: prayag-app
        environment: \${ENVIRONMENT}
    spec:
      containers:
      - name: prayag-app
        image: prayag8tiwari/prayag-new1-pipeline:\${IMAGE_TAG}
        ports:
        - containerPort: 8080
        env:
        - name: APP_NAME
          valueFrom:
            configMapKeyRef:
              name: prayag-app-config
              key: APP_NAME
        - name: ENVIRONMENT
          valueFrom:
            configMapKeyRef:
              name: prayag-app-config
              key: ENVIRONMENT
        resources:
          requests:
            memory: "\${MEMORY_REQUEST}"
            cpu: "\${CPU_REQUEST}"
          limits:
            memory: "\${MEMORY_LIMIT}"
            cpu: "\${CPU_LIMIT}"
        livenessProbe:
          httpGet:
            path: /
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
        imagePullPolicy: Always
EOF

    cat > gitops/base/service.yaml << EOF
apiVersion: v1
kind: Service
metadata:
  name: prayag-app-service
  namespace: prayag-app
  labels:
    app: prayag-app
    environment: \${ENVIRONMENT}
spec:
  type: \${SERVICE_TYPE}
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP
    name: http
  selector:
    app: prayag-app
EOF

    cat > gitops/base/kustomization.yaml << EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- namespace.yaml
- configmap.yaml
- deployment.yaml
- service.yaml

commonLabels:
  app: prayag-app
  project: prayag-new1-pipeline
EOF

    echo "✅ Base manifests created"
}

# Create environment-specific overlays
create_overlays() {
    echo "🎨 Creating environment-specific overlays..."
    
    # Dev environment
    cat > gitops/overlays/dev/kustomization.yaml << EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- ../../base

patchesStrategicMerge:
- configmap-patch.yaml
- deployment-patch.yaml
- service-patch.yaml

namePrefix: dev-
commonLabels:
  environment: dev
EOF

    cat > gitops/overlays/dev/configmap-patch.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: prayag-app-config
  namespace: prayag-app
data:
  ENVIRONMENT: "dev"
  APP_VERSION: "1.0.0-dev"
  DEBUG_MODE: "true"
  LOG_LEVEL: "debug"
EOF

    cat > gitops/overlays/dev/deployment-patch.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prayag-app-deployment
  namespace: prayag-app
spec:
  replicas: 1
  template:
    spec:
      containers:
      - name: prayag-app
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
EOF

    cat > gitops/overlays/dev/service-patch.yaml << EOF
apiVersion: v1
kind: Service
metadata:
  name: prayag-app-service
  namespace: prayag-app
spec:
  type: NodePort
  ports:
  - port: 80
    targetPort: 8080
    nodePort: 30080
EOF

    # QA environment
    cat > gitops/overlays/qa/kustomization.yaml << EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- ../../base

patchesStrategicMerge:
- configmap-patch.yaml
- deployment-patch.yaml
- service-patch.yaml

namePrefix: qa-
commonLabels:
  environment: qa
EOF

    cat > gitops/overlays/qa/configmap-patch.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: prayag-app-config
  namespace: prayag-app
data:
  ENVIRONMENT: "qa"
  APP_VERSION: "1.0.0-qa"
  DEBUG_MODE: "false"
  LOG_LEVEL: "info"
EOF

    cat > gitops/overlays/qa/deployment-patch.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prayag-app-deployment
  namespace: prayag-app
spec:
  replicas: 2
  template:
    spec:
      containers:
      - name: prayag-app
        resources:
          requests:
            memory: "256Mi"
            cpu: "200m"
          limits:
            memory: "512Mi"
            cpu: "400m"
EOF

    cat > gitops/overlays/qa/service-patch.yaml << EOF
apiVersion: v1
kind: Service
metadata:
  name: prayag-app-service
  namespace: prayag-app
spec:
  type: NodePort
  ports:
  - port: 80
    targetPort: 8080
    nodePort: 30081
EOF

    # Prod environment
    cat > gitops/overlays/prod/kustomization.yaml << EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- ../../base

patchesStrategicMerge:
- configmap-patch.yaml
- deployment-patch.yaml
- service-patch.yaml
- hpa.yaml

namePrefix: prod-
commonLabels:
  environment: prod
EOF

    cat > gitops/overlays/prod/configmap-patch.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: prayag-app-config
  namespace: prayag-app
data:
  ENVIRONMENT: "prod"
  APP_VERSION: "1.0.0"
  DEBUG_MODE: "false"
  LOG_LEVEL: "warn"
EOF

    cat > gitops/overlays/prod/deployment-patch.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prayag-app-deployment
  namespace: prayag-app
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: prayag-app
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
EOF

    cat > gitops/overlays/prod/service-patch.yaml << EOF
apiVersion: v1
kind: Service
metadata:
  name: prayag-app-service
  namespace: prayag-app
spec:
  type: NodePort
  ports:
  - port: 80
    targetPort: 8080
    nodePort: 30082
EOF

    cat > gitops/overlays/prod/hpa.yaml << EOF
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: prayag-app-hpa
  namespace: prayag-app
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: prayag-app-deployment
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
EOF

    echo "✅ Environment overlays created"
}

# Create ArgoCD applications
create_argocd_applications() {
    echo "📱 Creating ArgoCD applications..."
    
    # Dev application
    cat > gitops/applications/dev-app.yaml << EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: prayag-app-dev
  namespace: argocd
  finalizers:
  - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/Phoenix-ctrl-cpu/Prayag-new1
    targetRevision: HEAD
    path: gitops/overlays/dev
  destination:
    server: https://kubernetes.default.svc
    namespace: prayag-app
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
    - PrunePropagationPolicy=foreground
    - PruneLast=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
EOF

    # QA application
    cat > gitops/applications/qa-app.yaml << EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: prayag-app-qa
  namespace: argocd
  finalizers:
  - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/Phoenix-ctrl-cpu/Prayag-new1
    targetRevision: HEAD
    path: gitops/overlays/qa
  destination:
    server: https://kubernetes.default.svc
    namespace: prayag-app
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
    - PrunePropagationPolicy=foreground
    - PruneLast=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
EOF

    # Prod application
    cat > gitops/applications/prod-app.yaml << EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: prayag-app-prod
  namespace: argocd
  finalizers:
  - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/Phoenix-ctrl-cpu/Prayag-new1
    targetRevision: HEAD
    path: gitops/overlays/prod
  destination:
    server: https://kubernetes.default.svc
    namespace: prayag-app
  syncPolicy:
    automated:
      prune: false
      selfHeal: false
    syncOptions:
    - CreateNamespace=true
    - PrunePropagationPolicy=foreground
    - PruneLast=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
EOF

    echo "✅ ArgoCD applications created"
}

# Create ArgoCD project
create_argocd_project() {
    echo "📋 Creating ArgoCD project..."
    
    cat > gitops/projects/prayag-project.yaml << EOF
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: prayag-project
  namespace: argocd
spec:
  description: Prayag Application Project
  sourceRepos:
  - 'https://github.com/Phoenix-ctrl-cpu/Prayag-new1'
  destinations:
  - namespace: 'prayag-app'
    server: 'https://kubernetes.default.svc'
  - namespace: 'prayag-app'
    server: 'https://argocd-dev-control-plane:6443'
  - namespace: 'prayag-app'
    server: 'https://argocd-qa-control-plane:6443'
  - namespace: 'prayag-app'
    server: 'https://argocd-prod-control-plane:6443'
  clusterResourceWhitelist:
  - group: ''
    kind: Namespace
  - group: ''
    kind: Node
  - group: ''
    kind: PersistentVolume
  namespaceResourceWhitelist:
  - group: ''
    kind: '*'
  - group: 'apps'
    kind: '*'
  - group: 'autoscaling'
    kind: '*'
  - group: 'networking.k8s.io'
    kind: '*'
  roles:
  - name: admin
    description: Admin role
    policies:
    - p, proj:prayag-project:admin, applications, *, prayag-project/*, allow
    - p, proj:prayag-project:admin, repositories, *, *, allow
    groups:
    - 'argocd-admins'
  - name: developer
    description: Developer role
    policies:
    - p, proj:prayag-project:developer, applications, get, prayag-project/*, allow
    - p, proj:prayag-project:developer, applications, sync, prayag-project/*, allow
    groups:
    - 'argocd-developers'
EOF

    echo "✅ ArgoCD project created"
}

# Main execution
main() {
    create_base_manifests
    create_overlays
    create_argocd_applications
    create_argocd_project
    
    echo "🎉 GitOps repository setup completed!"
    echo ""
    echo "📋 Next steps:"
    echo "1. Commit and push these changes to your Git repository"
    echo "2. Run ./deploy-applications.sh to deploy ArgoCD applications"
    echo "3. Access ArgoCD UI to see your applications"
}

main "$@"