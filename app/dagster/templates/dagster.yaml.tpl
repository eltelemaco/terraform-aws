# Dagster Instance Configuration
# This configures the Dagster instance for production deployment on Kubernetes

# Storage Configuration
storage:
  postgres:
    postgres_db:
      username: "${postgresql_username}"
      password:
        env: DAGSTER_PG_PASSWORD
      hostname: "${postgresql_host}"
      port: ${postgresql_port}
      db_name: "${postgresql_database}"

# Run Launcher Configuration
run_launcher:
%{ if run_launcher_type == "K8sRunLauncher" ~}
  module: dagster_k8s.launcher
  class: K8sRunLauncher
  config:
    service_account_name: dagster
    job_namespace: "${namespace}"
    load_incluster_config: true
    job_image: "dagster/dagster-k8s:${dagster_version}"
    image_pull_policy: "IfNotPresent"
    env_config_maps:
      - dagster-instance-config
    resources:
      requests:
        cpu: "100m"
        memory: "256Mi"
      limits:
        cpu: "500m"
        memory: "1Gi"
%{ endif ~}
%{ if run_launcher_type == "CeleryK8sRunLauncher" ~}
  module: dagster_celery_k8s.launcher
  class: CeleryK8sRunLauncher
  config:
    service_account_name: dagster
    job_namespace: "${namespace}"
    load_incluster_config: true
    job_image: "dagster/dagster-k8s:${dagster_version}"
    image_pull_policy: "IfNotPresent"
    env_config_maps:
      - dagster-instance-config
    resources:
      requests:
        cpu: "100m"
        memory: "256Mi"
      limits:
        cpu: "500m"
        memory: "1Gi"
    # Celery configuration
    celery_config:
      broker_url:
        env: DAGSTER_CELERY_BROKER_URL
      result_backend:
        env: DAGSTER_CELERY_RESULT_BACKEND
%{ endif ~}

# Run Coordinator
run_coordinator:
  module: dagster.core.run_coordinator
  class: QueuedRunCoordinator
  config:
    max_concurrent_runs: 10

# Compute Log Manager
%{ if enable_s3_logs ~}
compute_logs:
  module: dagster_aws.s3.compute_log_manager
  class: S3ComputeLogManager
  config:
    bucket: "${s3_bucket_name}"
    region: "${aws_region}"
    prefix: "dagster-compute-logs"
    show_url_only: true
%{ else ~}
compute_logs:
  module: dagster.core.storage.noop_compute_log_manager
  class: NoOpComputeLogManager
%{ endif ~}

# Event Log Storage
event_log_storage:
  module: dagster_postgres.event_log
  class: DagsterPostgresEventLogStorage
  config:
    postgres_db:
      username: "${postgresql_username}"
      password:
        env: DAGSTER_PG_PASSWORD
      hostname: "${postgresql_host}"
      port: ${postgresql_port}
      db_name: "${postgresql_database}"

# Schedule Storage
schedule_storage:
  module: dagster_postgres.schedule_storage
  class: DagsterPostgresScheduleStorage
  config:
    postgres_db:
      username: "${postgresql_username}"
      password:
        env: DAGSTER_PG_PASSWORD
      hostname: "${postgresql_host}"
      port: ${postgresql_port}
      db_name: "${postgresql_database}"

# Data Retention
retention:
  schedule:
    purge_after_days: 30
  sensor:
    purge_after_days: 30

# Sensors
sensors:
  use_threads: true
  num_workers: 4

# Schedules
schedules:
  use_threads: true
  num_workers: 4

# Run Monitoring
run_monitoring:
  enabled: true
  poll_interval_seconds: 120
  max_resume_run_attempts: 3

# Code Servers
code_servers:
  local_startup_timeout: 60
  wait_for_local_processes_on_shutdown: true
