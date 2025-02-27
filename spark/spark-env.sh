#!/bin/bash

# ------------------------------------------------
# SPARK ENVIRONMENT CONFIGURATION
# ------------------------------------------------

# IP and DNS settings
# Note: 0.0.0.0 bindings should be changed to specific interfaces in production
export SPARK_LOCAL_IP=0.0.0.0
export SPARK_PUBLIC_DNS=localhost

# Hadoop integration
export HADOOP_HOME=/opt/hadoop
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
export SPARK_DIST_CLASSPATH=$(hadoop classpath)

# Directory settings with proper permissions
export SPARK_LOG_DIR=/opt/spark/logs
export SPARK_WORKER_DIR=/opt/spark/work

# Master settings
# Note: 0.0.0.0 bindings should be changed to specific interfaces in production
export SPARK_MASTER_HOST=0.0.0.0
export SPARK_MASTER_BIND_ADDRESS=0.0.0.0
export SPARK_MASTER_WEBUI_HOST=0.0.0.0

# Memory and JVM settings
export SPARK_DAEMON_MEMORY=2g
export SPARK_DAEMON_JAVA_OPTS="-XX:+UseG1GC -XX:MaxGCPauseMillis=100"

# ------------------------------------------------
# SECURITY CONFIGURATIONS
# ------------------------------------------------

# User to run the daemons as
export SPARK_IDENT_STRING=hadoop

# Authentication settings
export SPARK_AUTH_SECRET_FILE=/opt/spark/conf/.secret
# Generate a secret key if it doesn't exist
if [ ! -f "$SPARK_AUTH_SECRET_FILE" ]; then
  openssl rand -base64 32 > "$SPARK_AUTH_SECRET_FILE"
  chmod 600 "$SPARK_AUTH_SECRET_FILE"
  chown hadoop:hadoop "$SPARK_AUTH_SECRET_FILE"
fi

# Export secret for spark-defaults.conf
export SPARK_AUTH_SECRET_FILE_CONTENTS=$(cat "$SPARK_AUTH_SECRET_FILE")

# Create Java security policy file
cat > /opt/spark/conf/spark.policy << EOF
grant {
  permission java.io.FilePermission "<<ALL FILES>>", "read,write,delete,execute";
  permission java.lang.RuntimePermission "*";
  permission java.util.PropertyPermission "*", "read,write";
  permission java.net.SocketPermission "*", "connect,accept,resolve";
};
EOF
chmod 644 /opt/spark/conf/spark.policy

# Create HDFS directory for Spark logs
hadoop fs -mkdir -p /spark-logs
hadoop fs -chmod -R 755 /spark-logs
hadoop fs -chown -R hadoop:hadoop /spark-logs

# Set proper umask for better file permissions
umask 027

# Create necessary directories with proper permissions
mkdir -p /opt/spark/tmp
chmod 750 /opt/spark/tmp
chown hadoop:hadoop /opt/spark/tmp

# Configure Spark to use the configured hadoop user
export HADOOP_USER_NAME=hadoop
