# Security Setup Guide for Big Data Environment

This document outlines the comprehensive security setup for our big data environment that includes Apache Airflow, Hadoop, and Spark. Follow these steps to implement the security controls necessary to protect your data and infrastructure.

## Table of Contents

1. [Security Overview](#security-overview)
2. [Directory Structure](#directory-structure)
3. [Secrets Management](#secrets-management)
4. [SSL Certificate Generation](#ssl-certificate-generation)
5. [Security Configuration Files](#security-configuration-files)
6. [Network Security](#network-security)
7. [User Management](#user-management)
8. [Container Security](#container-security)
9. [Service-Specific Security](#service-specific-security)
10. [Security Testing](#security-testing)
11. [Maintenance and Updates](#maintenance-and-updates)

## Security Overview

Our security approach follows defense-in-depth principles, implementing multiple layers of security controls:

* **Authentication**: Secret-based authentication for services
* **Authorization**: Role-based access control (RBAC) for Airflow and ACLs for Hadoop/Spark
* **Encryption**: SSL/TLS for web interfaces and data in transit
* **Isolation**: Container isolation, network segmentation, and resource limits
* **Least Privilege**: Non-root users and minimal permissions
* **Secure Configuration**: Hardened configuration files for all services
* **Monitoring**: Comprehensive logging and audit trails

## Directory Structure

Create the following directory structure for security files:

```
project-root/
├── docker/
│   └── Dockerfile.spark        # Security-hardened Dockerfile
├── secrets/                    # Store all sensitive information
│   ├── airflow_admin_password.txt
│   ├── airflow_db_conn.txt
│   ├── airflow.crt
│   ├── airflow.key
│   ├── postgres_password.txt
│   └── spark_secret.txt
├── spark/
│   ├── spark-defaults.conf    # Security-hardened config
│   ├── spark-env.sh          # Security-hardened config
│   ├── spark.policy          # Java security policy for Spark
│   └── fairscheduler.xml     # Resource allocation policy
├── hadoop/
│   ├── java.security         # Java security properties
│   ├── core-site.xml         # Security-hardened config
│   ├── hdfs-site.xml         # Security-hardened config
│   └── yarn-site.xml         # Security-hardened config
├── scripts/
│   ├── entrypoint.sh         # Security-hardened script
│   └── combined-entrypoint.sh # Security-hardened script
├── docker-compose.yml         # Security-hardened compose file
└── README.md                  # Project documentation
```

## Secrets Management

### 1. Create Secret Files

```bash
# Create secrets directory with restricted permissions
mkdir -p ./secrets
chmod 700 ./secrets

# Generate secure passwords
openssl rand -base64 32 | tr -d '\n' > ./secrets/postgres_password.txt
openssl rand -base64 32 | tr -d '\n' > ./secrets/airflow_admin_password.txt

# Create database connection string
POSTGRES_PASSWORD=$(cat ./secrets/postgres_password.txt)
echo "postgresql+psycopg2://airflow:${POSTGRES_PASSWORD}@postgres/airflow" > ./secrets/airflow_db_conn.txt

# Generate Spark authentication secret
openssl rand -base64 32 > ./secrets/spark_secret.txt

# Secure all secret files
chmod 600 ./secrets/*
```

## SSL Certificate Generation

### 1. Generate Self-Signed Certificates

```bash
# Generate SSL certificate for Airflow webserver
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout ./secrets/airflow.key \
  -out ./secrets/airflow.crt \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=airflow"

# Set proper permissions
chmod 600 ./secrets/airflow.key
chmod 644 ./secrets/airflow.crt
```

### 2. For Production (Recommended)

In production environments, replace self-signed certificates with certificates from a trusted Certificate Authority.

## Security Configuration Files

### 1. Java Security Policy for Spark (./spark/spark.policy)

Create a Java security policy for Spark:

```
grant {
  permission java.io.FilePermission "<<ALL FILES>>", "read,write,delete,execute";
  permission java.lang.RuntimePermission "*";
  permission java.util.PropertyPermission "*", "read,write";
  permission java.net.SocketPermission "*", "connect,accept,resolve";
  
  // Restrict access to security sensitive packages
  permission java.lang.RuntimePermission "accessClassInPackage.sun.*";
  permission java.lang.RuntimePermission "accessClassInPackage.com.sun.*";
};
```

### 2. Java Security Properties (./hadoop/java.security)

```
# Java Security Properties for Hadoop
security.provider.1=sun.security.provider.Sun
security.provider.2=sun.security.rsa.SunRsaSign
security.provider.3=com.sun.net.ssl.internal.ssl.Provider
security.provider.4=com.sun.crypto.provider.SunJCE
security.provider.5=sun.security.jgss.SunProvider

# Disable weak algorithms
jdk.tls.disabledAlgorithms=SSLv3, TLSv1, TLSv1.1, RC4, DES, MD5withRSA, DH keySize < 1024, EC keySize < 224, 3DES_EDE_CBC, anon, NULL
jdk.certpath.disabledAlgorithms=MD2, MD5, SHA1 jdkCA & usage TLSServer, RSA keySize < 2048
jdk.tls.legacyAlgorithms=

# Strong crypto settings
crypto.policy=unlimited

# Secure random settings
securerandom.source=file:/dev/urandom
```

### 3. Access Control Configuration

Create a fair scheduler XML file (./spark/fairscheduler.xml):

```xml
<?xml version="1.0"?>
<allocations>
  <pool name="production">
    <schedulingMode>FAIR</schedulingMode>
    <weight>2</weight>
    <minShare>1</minShare>
  </pool>
  <pool name="development">
    <schedulingMode>FAIR</schedulingMode>
    <weight>1</weight>
    <minShare>1</minShare>
  </pool>
  <pool name="default">
    <schedulingMode>FIFO</schedulingMode>
    <weight>1</weight>
    <minShare>1</minShare>
  </pool>
  <defaultFairSharePreemptionTimeout>120</defaultFairSharePreemptionTimeout>
  <fairSharePreemptionThreshold>0.5</fairSharePreemptionThreshold>
</allocations>
```

## Network Security

### 1. Configure Network Settings

Update the docker-compose.yml file to bind services to localhost:

```yaml
ports:
  - "127.0.0.1:8080:8080"  # Instead of "8080:8080"
```

### 2. Network Isolation

Configure an isolated network for your services:

```yaml
networks:
  hadoop_network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.28.0.0/16
          gateway: 172.28.0.1
```

### 3. Firewall Rules (Host Level)

Apply host-level firewall rules to restrict access:

```bash
# Example for UFW (Ubuntu)
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow from 127.0.0.1 to any port 8080 proto tcp  # Airflow UI
sudo ufw allow from 127.0.0.1 to any port 8088 proto tcp  # YARN UI
sudo ufw allow from 127.0.0.1 to any port 9870 proto tcp  # HDFS UI
sudo ufw allow from 127.0.0.1 to any port 8181 proto tcp  # Spark Master UI
sudo ufw enable
```

## User Management

### 1. Create Service Users

Ensure service users are created in the Dockerfile:

```dockerfile
# Create service users with no login shell
RUN groupadd -r hadoop && \
    useradd -r -g hadoop -d /home/hadoop -s /sbin/nologin hadoop && \
    groupadd -r airflow && \
    useradd -r -g airflow -d /home/airflow -s /sbin/nologin airflow
```

### 2. Set Proper Permissions

Set proper permissions for all service directories:

```dockerfile
# Set proper permissions
RUN mkdir -p /opt/hadoop/dfs/name /opt/hadoop/dfs/data /opt/hadoop/logs && \
    chown -R hadoop:hadoop /opt/hadoop && \
    chmod -R 750 /opt/hadoop/etc/hadoop && \
    chmod -R 770 /opt/hadoop/dfs /opt/hadoop/logs
    
RUN mkdir -p /opt/spark/logs /opt/spark/work-dir && \
    chown -R hadoop:hadoop /opt/spark && \
    chmod -R 750 /opt/spark/conf && \
    chmod -R 770 /opt/spark/logs /opt/spark/work-dir
```

## Container Security

### 1. Apply Security Options

Update the docker-compose.yml to include security options:

```yaml
security_opt:
  - no-new-privileges:true
```

### 2. Resource Limits

Set resource limits for all containers:

```yaml
deploy:
  resources:
    limits:
      cpus: '1.0'
      memory: 2G
```

### 3. Read-Only Filesystem

Make filesystems read-only where possible:

```yaml
volumes:
  - ./dags:/opt/airflow/dags:ro  # Read-only volumes
read_only: true  # Read-only filesystem
tmpfs:
  - /tmp  # Writable temporary directory
```

## Service-Specific Security

### Airflow Security

1. Enable RBAC and secure mode:

```yaml
environment:
  - AIRFLOW__WEBSERVER__RBAC=True
  - AIRFLOW__CORE__SECURE_MODE=True
```

2. Enable SSL for the web interface:

```yaml
environment:
  - AIRFLOW__WEBSERVER__WEB_SERVER_SSL_CERT=/run/secrets/airflow_cert
  - AIRFLOW__WEBSERVER__WEB_SERVER_SSL_KEY=/run/secrets/airflow_key
```

### Hadoop Security

1. Apply security settings in hadoop.env:

```
HADOOP_SECURE_MODE=true
HADOOP_OPTS=-Djava.security.properties=/opt/hadoop/conf/java.security
```

2. Use service-specific users:

```yaml
environment:
  - HDFS_NAMENODE_USER=hadoop
  - HDFS_DATANODE_USER=hadoop
  - YARN_RESOURCEMANAGER_USER=hadoop
  - YARN_NODEMANAGER_USER=hadoop
```

### Spark Security

1. Enable authentication:

```yaml
environment:
  - SPARK_AUTH_SECRET_FILE=/run/secrets/spark_secret
```

2. Use proper security settings in spark-defaults.conf:

```
spark.authenticate=true
spark.ui.filters=org.apache.spark.ui.filters.SecurityFilter
spark.acls.enable=true
```

## Security Testing

### 1. Vulnerability Scanning

Scan images for vulnerabilities:

```bash
# Install Trivy
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

# Scan the Spark image
trivy image airflow-spark:latest
```

### 2. Security Audit

Perform a security audit of the Docker Compose file:

```bash
# Install docker-compose-audit
pip install docker-compose-audit

# Audit the file
docker-compose-audit docker-compose.yml
```

### 3. Configuration Testing

Test configuration files for security issues:

```bash
# Test Hadoop XML files for security misconfigurations
hadoop checknative -a
hdfs dfsadmin -report
```

## Maintenance and Updates

### 1. Regular Updates

Keep all images and dependencies updated:

```bash
# Check for updates
docker pull postgres:13
docker build --no-cache -t airflow-spark:latest -f docker/Dockerfile.spark .
```

### 2. Security Patching

Establish a regular security patching schedule:

```bash
# Inside container
apt-get update && apt-get upgrade -y
```

### 3. Audit Logs

Configure comprehensive logging:

```yaml
# Enable log aggregation in yarn-site.xml
<property>
  <name>yarn.log-aggregation-enable</name>
  <value>true</value>
</property>

# Enable event logging in spark-defaults.conf
spark.eventLog.enabled=true
spark.history.fs.logDirectory=hdfs://namenode:9000/spark-logs
```

## Security Checklist

Before deploying to production, ensure:

- [x] All default/weak passwords have been changed
- [x] Secrets are properly stored and not in version control
- [x] SSL certificates are properly configured
- [x] Services bind only to necessary interfaces
- [x] Containers run with non-root users where possible
- [x] Container resource limits are properly set
- [x] Network access is properly restricted
- [x] All configuration files have appropriate permissions
- [x] Authentication is enabled for all services
- [x] Authorization/ACLs are properly configured
- [x] All ports exposed are necessary and secured
- [x] Logging and monitoring are enabled
- [x] Security scanning and updates are scheduled
