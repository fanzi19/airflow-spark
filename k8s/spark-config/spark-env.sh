#!/bin/bash

# Original settings
export SPARK_LOCAL_IP=0.0.0.0
export SPARK_PUBLIC_DNS=localhost
export HADOOP_HOME=/opt/hadoop
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
export SPARK_DIST_CLASSPATH=$(hadoop classpath)
export SPARK_LOG_DIR=/opt/spark/logs
export SPARK_WORKER_DIR=/opt/spark/work

# Add these new settings
export SPARK_MASTER_HOST=0.0.0.0
export SPARK_MASTER_BIND_ADDRESS=0.0.0.0
export SPARK_MASTER_WEBUI_HOST=0.0.0.0
export SPARK_DAEMON_MEMORY=2g
export SPARK_DAEMON_JAVA_OPTS="-XX:+UseG1GC -XX:MaxGCPauseMillis=100"
