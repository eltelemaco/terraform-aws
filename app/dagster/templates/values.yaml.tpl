# Dagster Helm Chart Values
# Production-ready configuration for EKS deployment

global:
  # PostgreSQL configuration
  postgresqlSecretName: "${postgresql_secret_name}"

# Dagster configuration
dagster:
  # Enable user deployments
  enableSubchart: true
  
# PostgreSQL Configuration
postgresql:
  enabled: ${postgresql_enabled}
%{ if !postgresql_enabled ~}
  postgresqlHost: "${postgresql_host}"
  postgresqlPort: ${postgresql_port}
  postgresqlUsername: "${postgresql_username}"
  postgresqlDatabase: "${postgresql_database}"
  service:
    port: ${postgresql_port}
%{ endif ~}
%{ if postgresql_enabled ~}
  auth:
    database: "${postgresql_database}"
    username: "${postgresql_username}"
    postgresPassword: "dagster123"
  primary:
    persistence:
      enabled: true
      size: 10Gi
      storageClass: "gp3"
    resources:
      requests:
        memory: "256Mi"
        cpu: "250m"
      limits:
        memory: "1Gi"
        cpu: "500m"
%{ endif ~}

# Secret configuration
generatePostgresqlPasswordSecret: ${use_existing_secret ? "false" : "true"}

# Service Account
serviceAccount:
  create: ${create_service_account}
  name: "${service_account_name}"

# Image configuration
dagsterWebserver:
  image:
    repository: "dagster/dagster-k8s"
    tag: "${dagster_version}"
    pullPolicy: "IfNotPresent"
  
  # Webserver scaling
  replicaCount: ${replicas}
  
  # Webserver resources
  resources:
    requests:
      cpu: "${webserver_resources.requests.cpu}"
      memory: "${webserver_resources.requests.memory}"
    limits:
      cpu: "${webserver_resources.limits.cpu}"
      memory: "${webserver_resources.limits.memory}"
  
  # Webserver configuration
  env:
    DAGSTER_HOME: "/opt/dagster/dagster_home"
    DAGSTER_K8S_PIPELINE_RUN_NAMESPACE: "${namespace}"
    DAGSTER_K8S_PIPELINE_RUN_ENV_CONFIGMAP: "dagster-instance-config"
  
  # Liveness and readiness probes
  livenessProbe:
    httpGet:
      path: "/dagster-webserver/health"
      port: 3000
    initialDelaySeconds: 60
    periodSeconds: 20
    timeoutSeconds: 10
    failureThreshold: 3
  
  readinessProbe:
    httpGet:
      path: "/dagster-webserver/health"
      port: 3000
    initialDelaySeconds: 30
    periodSeconds: 10
    timeoutSeconds: 5
    failureThreshold: 3

# Daemon configuration
dagsterDaemon:
  image:
    repository: "dagster/dagster-k8s"
    tag: "${dagster_version}"
    pullPolicy: "IfNotPresent"
  
  # Daemon resources
  resources:
    requests:
      cpu: "${daemon_resources.requests.cpu}"
      memory: "${daemon_resources.requests.memory}"
    limits:
      cpu: "${daemon_resources.limits.cpu}"
      memory: "${daemon_resources.limits.memory}"
  
  # Daemon environment
  env:
    DAGSTER_HOME: "/opt/dagster/dagster_home"

# Run Launcher Configuration
runLauncher:
  type: "${run_launcher_type}"
  config:
%{ if run_launcher_type == "K8sRunLauncher" ~}
    k8sRunLauncher:
      serviceAccountName: "${service_account_name}"
      jobNamespace: "${namespace}"
      loadInclusterConfig: true
      imagePullPolicy: "IfNotPresent"
      envConfigMaps:
        - "dagster-instance-config"
      resources:
        requests:
          cpu: "${k8s_run_launcher_config.resources.requests.cpu}"
          memory: "${k8s_run_launcher_config.resources.requests.memory}"
        limits:
          cpu: "${k8s_run_launcher_config.resources.limits.cpu}"
          memory: "${k8s_run_launcher_config.resources.limits.memory}"
%{ endif ~}
%{ if run_launcher_type == "CeleryK8sRunLauncher" ~}
    celeryK8sRunLauncher:
      serviceAccountName: "${service_account_name}"
      jobNamespace: "${namespace}"
      loadInclusterConfig: true
      imagePullPolicy: "IfNotPresent"
      envConfigMaps:
        - "dagster-instance-config"
      resources:
        requests:
          cpu: "${k8s_run_launcher_config.resources.requests.cpu}"
          memory: "${k8s_run_launcher_config.resources.requests.memory}"
        limits:
          cpu: "${k8s_run_launcher_config.resources.limits.cpu}"
          memory: "${k8s_run_launcher_config.resources.limits.memory}"
%{ endif ~}

# Celery configuration (if using CeleryK8sRunLauncher)
%{ if run_launcher_type == "CeleryK8sRunLauncher" ~}
rabbitmq:
  enabled: true
  auth:
    username: "dagster"
    password: "dagster123"
  resources:
    requests:
      memory: "256Mi"
      cpu: "100m"
    limits:
      memory: "512Mi"
      cpu: "200m"

celery:
  replicaCount: 2
  resources:
    requests:
      cpu: "100m"
      memory: "256Mi"
    limits:
      cpu: "500m"
      memory: "1Gi"
%{ endif ~}

# User Code Deployments
dagster-user-deployments:
  enableSubchart: true
  
  # User code deployments configuration
  deployments:
    - name: "dagster-user-code"
      image:
        repository: "dagster/dagster-k8s"
        tag: "${dagster_version}"
        pullPolicy: "IfNotPresent"
      
      # User code resources
      resources:
        requests:
          cpu: "${user_deployments_resources.requests.cpu}"
          memory: "${user_deployments_resources.requests.memory}"
        limits:
          cpu: "${user_deployments_resources.limits.cpu}"
          memory: "${user_deployments_resources.limits.memory}"
      
      # User code configuration
      port: 3030
      env:
        DAGSTER_CURRENT_IMAGE: "dagster/dagster-k8s:${dagster_version}"
      
      service:
        type: ClusterIP
        port: 3030

# Ingress configuration
ingress:
  enabled: ${ingress_enabled}
%{ if ingress_enabled ~}
  className: "${ingress_class}"
  host: "${ingress_host}"
  annotations:
    kubernetes.io/ingress.class: "${ingress_class}"
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
    alb.ingress.kubernetes.io/ssl-redirect: '443'
    alb.ingress.kubernetes.io/healthcheck-path: "/dagster-webserver/health"
  tls:
    enabled: true
    secretName: "dagster-tls"
%{ endif ~}

# Security Context
securityContext:
  runAsUser: 1000
  runAsGroup: 1000
  fsGroup: 1000

# Pod Security Context
podSecurityContext:
  runAsNonRoot: true
  runAsUser: 1000
  runAsGroup: 1000
  fsGroup: 1000

# Network Policies
%{ if enable_network_policies ~}
networkPolicy:
  enabled: true
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              name: "${namespace}"
  egress:
    - to: []
%{ endif ~}

# Monitoring
%{ if enable_prometheus_monitoring ~}
serviceMonitor:
  enabled: true
  namespace: "${namespace}"
  interval: 30s
  scrapeTimeout: 10s
%{ endif ~}

# Node Selection
nodeSelector: {}

# Tolerations
tolerations: []

# Affinity
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        labelSelector:
          matchExpressions:
          - key: app.kubernetes.io/name
            operator: In
            values:
            - dagster
        topologyKey: kubernetes.io/hostname

# Priority Class
priorityClassName: ""

# Development/Debug mode
%{ if enable_debug_mode ~}
dagsterWebserver:
  env:
    DAGSTER_DEBUG: "true"
    DAGSTER_LOG_LEVEL: "DEBUG"

dagsterDaemon:
  env:
    DAGSTER_DEBUG: "true"
    DAGSTER_LOG_LEVEL: "DEBUG"
%{ endif ~}
