# Airflow with Hadoop and Spark Platform

This repository contains a complete setup for running Apache Airflow integrated with Hadoop and Spark for data processing workflows. The platform can be deployed either using Docker Compose for local development or Kubernetes for production environments.

## Repository Structure

```
├── .github/             # GitHub Actions workflows
├── docker/              # Docker configuration files
├── hadoop/              # Hadoop configuration files
├── spark/               # Spark configuration files
├── k8s/                 # Kubernetes manifests
├── dags/                # Airflow DAG files
└── docker-compose.yml   # Docker Compose configuration
```

## Deployment Options

### Local Development with Docker

The Docker-based setup is recommended for:
- Local development and testing
- Quick setup with minimal configuration
- Single-machine deployments
- Proof of concept work

To start the platform using Docker:

```bash
# Build and start all services
docker-compose up -d

# Check the status
docker-compose ps

# View logs
docker-compose logs -f airflow-webserver
```

### Production Deployment with Kubernetes

The Kubernetes setup is recommended for:
- Production environments
- Multi-node deployments
- High availability requirements
- Scalable workloads
- Cloud deployments

To deploy on Kubernetes:

```bash
# Apply the Kubernetes manifests
kubectl apply -k k8s/

# Check the status
kubectl get pods

# View logs
kubectl logs -f deployment/airflow-webserver
```

## Prerequisites for Building Docker Images

### Required Downloads

Before building the Docker images, you need to download specific versions of Hadoop and Spark. This approach speeds up the build process and allows for offline builds.

1. Create a `downloads` directory in the project root:
   ```bash
   mkdir -p downloads
   ```

2. Download the required distribution files:
   ```bash
   # Download Hadoop
   wget -P downloads https://downloads.apache.org/hadoop/common/hadoop-3.4.1/hadoop-3.4.1.tar.gz
   
   # Download Spark
   wget -P downloads https://downloads.apache.org/spark/spark-3.4.4/spark-3.4.4-bin-hadoop3.tgz
   ```

3. Verify files are in place:
   ```bash
   ls -la downloads/
   # Should show:
   # hadoop-3.4.1.tar.gz
   # spark-3.4.4-bin-hadoop3.tgz
   ```

The Dockerfiles are configured to copy these files from the `downloads` directory during the build process, as shown in this example:

```dockerfile
# Copy and extract Hadoop
COPY downloads/hadoop-${HADOOP_VERSION}.tar.gz /tmp/
RUN tar -xzf /tmp/hadoop-${HADOOP_VERSION}.tar.gz -C /opt/ \
    && ln -s /opt/hadoop-${HADOOP_VERSION} ${HADOOP_HOME} \
    && rm /tmp/hadoop-${HADOOP_VERSION}.tar.gz
```

This approach:
- Reduces build time by avoiding repeated downloads
- Enables building in environments without internet access
- Ensures consistent builds with specific versions

## Configuration

### Hadoop Configuration

Hadoop is configured via XML files located in:
- `hadoop/hadoop-config/` for Docker deployment
- `k8s/xml-files/` for Kubernetes deployment

### Spark Configuration

Spark is configured via:
- `spark/spark-defaults.conf` for Docker deployment
- `k8s/xml-files/` for Kubernetes deployment

### Airflow DAGs

Place your Airflow DAGs in the `dags/` directory. They will be automatically loaded by both deployment methods.

## Development Workflow

1. Develop and test your data pipelines locally using the Docker setup
2. Once tested, use the same DAGs and configurations in the Kubernetes environment
3. CI/CD pipelines in `.github/workflows/` automate testing and deployment

## Additional Prerequisites

### For Docker Deployment
- Docker and Docker Compose
- Minimum 8GB RAM allocated to Docker
- 20GB free disk space

### For Kubernetes Deployment
- Kubernetes cluster (v1.19+)
- kubectl configured to access your cluster
- Persistent volumes capability
- Helm (optional, for advanced deployments)

## Troubleshooting

Common issues:
- **Services fail to start**: Check Docker logs and ensure sufficient resources
- **Connectivity issues**: Verify network settings in docker-compose.yml
- **Kubernetes pods pending**: Check PVC provisioning and resource quotas
- **Build failures**: Ensure the required distribution files are properly downloaded in the `downloads` directory

For more detailed troubleshooting, refer to the logs of the specific component.
