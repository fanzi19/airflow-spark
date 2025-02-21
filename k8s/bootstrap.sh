#!/bin/bash

set -e

# Function for logging
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Configure SSH
if [ ! -f "/root/.ssh/id_rsa" ]; then
    ssh-keygen -t rsa -P '' -f /root/.ssh/id_rsa
    cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
    chmod 0600 /root/.ssh/authorized_keys
fi

# Start SSH daemon
/usr/sbin/sshd

# Function to wait for service
wait_for_it() {
    local host="$1"
    local port="$2"
    local timeout=120
    local start_time=$(date +%s)
    
    while ! nc -z "$host" "$port"; do
        current_time=$(date +%s)
        elapsed=$((current_time - start_time))
        
        if [ $elapsed -ge $timeout ]; then
            log "Timeout waiting for $host:$port after ${timeout} seconds"
            return 1
        fi
        
        log "Waiting for $host:$port... (${elapsed}s elapsed)"
        sleep 5
    done
    log "$host:$port is available after ${elapsed}s"
}

# Function to start namenode
start_namenode() {
    log "Starting NameNode..."
    
    # Set proper permissions
    chown -R root:root $HADOOP_HOME
    chmod -R 755 $HADOOP_HOME
    
    # Create necessary directories with proper permissions
    mkdir -p $HADOOP_HOME/dfs/name
    chown -R root:root $HADOOP_HOME/dfs/name
    chmod -R 755 $HADOOP_HOME/dfs/name
    
    # Format namenode if necessary
    if [ ! -d "$HADOOP_HOME/dfs/name/current" ]; then
        log "Formatting NameNode..."
        $HADOOP_HOME/bin/hdfs namenode -format -force
    fi
    
    log "Starting HDFS NameNode daemon..."
    # Start namenode in the foreground
    exec $HADOOP_HOME/bin/hdfs --config $HADOOP_HOME/etc/hadoop namenode
}

# Function to start datanode
start_datanode() {
    log "Waiting for NameNode..."
    wait_for_it namenode 9000
    
    # Set proper permissions
    mkdir -p $HADOOP_HOME/dfs/data
    chown -R root:root $HADOOP_HOME/dfs/data
    chmod -R 755 $HADOOP_HOME/dfs/data
    
    log "Starting DataNode..."
    exec $HADOOP_HOME/bin/hdfs --config $HADOOP_HOME/etc/hadoop datanode
}

# Function to start resourcemanager
start_resourcemanager() {
    log "Waiting for NameNode..."
    wait_for_it namenode 9000
    
    log "Starting ResourceManager..."
    exec $HADOOP_HOME/bin/yarn --config $HADOOP_HOME/etc/hadoop resourcemanager
}

# Function to start nodemanager
start_nodemanager() {
    log "Waiting for ResourceManager..."
    wait_for_it resourcemanager 8031
    
    log "Starting NodeManager..."
    exec $HADOOP_HOME/bin/yarn --config $HADOOP_HOME/etc/hadoop nodemanager
}

# Function to start historyserver
start_historyserver() {
    log "Waiting for ResourceManager..."
    wait_for_it resourcemanager 8088
    
    log "Starting HistoryServer..."
    exec $HADOOP_HOME/bin/yarn --config $HADOOP_HOME/etc/hadoop historyserver
}

# Main script
log "Starting Hadoop component: $1"
case "$1" in
    namenode)
        start_namenode
        ;;
    datanode)
        start_datanode
        ;;
    resourcemanager)
        start_resourcemanager
        ;;
    nodemanager)
        start_nodemanager
        ;;
    historyserver)
        start_historyserver
        ;;
    *)
        log "Starting default NameNode..."
        start_namenode
        ;;
esac
