#!/bin/bash

# Function for logging
log() {
    echo "$(date "+%Y-%m-%d %H:%M:%S") - $1"
}

# Set secure umask
umask 027

# Function to check service health
check_service() {
    local service_name=$1
    local max_attempts=$2
    local wait_time=$3
    local check_cmd=$4
    
    log "Checking $service_name service health"
    local attempts=0
    
    while [ $attempts -lt $max_attempts ]; do
        if eval "$check_cmd"; then
            log "$service_name is healthy"
            return 0
        fi
        
        attempts=$((attempts + 1))
        log "$service_name not ready yet, attempt $attempts/$max_attempts"
        sleep $wait_time
    done
    
    log "ERROR: $service_name failed health check after $max_attempts attempts"
    return 1
}

# Function to setup security for services
setup_service_security() {
    local service_type=$1
    
    log "Setting up security for $service_type"
    
    if [ "$service_type" = "hadoop" ]; then
        # Ensure proper permissions for Hadoop directories
        if [ -d "/opt/hadoop/etc/hadoop" ]; then
            chmod -R 750 /opt/hadoop/etc/hadoop
            find /opt/hadoop/etc/hadoop -type f -name "*.xml" -exec chmod 640 {} \;
            find /opt/hadoop/etc/hadoop -type f -name "*.sh" -exec chmod 750 {} \;
        fi
        
        # Ensure data directories have proper permissions
        if [ -d "/opt/hadoop/dfs" ]; then
            chmod 750 /opt/hadoop/dfs
            find /opt/hadoop/dfs -type d -exec chmod 750 {} \;
        fi
        
    elif [ "$service_type" = "spark" ]; then
        # Ensure proper permissions for Spark config
        if [ -d "/opt/spark/conf" ]; then
            chmod -R 750 /opt/spark/conf
            find /opt/spark/conf -type f -exec chmod 640 {} \;
        fi
        
        # Generate Spark auth secret if needed
        if [ ! -f "/opt/spark/conf/.secret" ]; then
            log "Generating Spark authentication secret"
            mkdir -p /opt/spark/conf
            openssl rand -base64 32 > /opt/spark/conf/.secret
            chmod 600 /opt/spark/conf/.secret
        fi
    fi
}

log "Starting service with SERVICE_TYPE=$SERVICE_TYPE"

# Setup security based on service type
setup_service_security "$SERVICE_TYPE"

# Check for root execution
if [ "$(id -u)" -eq 0 ]; then
    # Check if we should drop privileges
    if [ -n "$RUN_AS_USER" ] && [ "$SERVICE_TYPE" != "hadoop" ] && [ "$SERVICE_TYPE" != "spark" ]; then
        log "Will execute as $RUN_AS_USER instead of root"
        if ! id -u "$RUN_AS_USER" &>/dev/null; then
            log "Creating user $RUN_AS_USER"
            useradd -m -s /bin/bash "$RUN_AS_USER"
        fi
    fi
fi

# Start the appropriate service
if [ "$SERVICE_TYPE" = "hadoop" ]; then
    log "Starting Hadoop service"
    
    # Ensure Hadoop directories exist with proper permissions
    mkdir -p /opt/hadoop/logs
    chmod 750 /opt/hadoop/logs
    
    # Start Hadoop service
    /bootstrap.sh "$@"
    
    # Check service health
    check_service "HDFS NameNode" 10 5 "hdfs dfsadmin -report &>/dev/null"
    
elif [ "$SERVICE_TYPE" = "spark" ]; then
    log "Starting Spark service"
    
    # Ensure Spark directories exist with proper permissions
    mkdir -p /opt/spark/logs /opt/spark/work
    chmod 750 /opt/spark/logs /opt/spark/work
    
    # Start Spark service
    /spark-entrypoint.sh "$@"
    
    # Check service health
    check_service "Spark Master" 10 5 "curl -s http://localhost:8080/json/ &>/dev/null"
    
else
    log "No specific service type specified"
    
    # Drop privileges if running as root and RUN_AS_USER is specified
    if [ "$(id -u)" -eq 0 ] && [ -n "$RUN_AS_USER" ]; then
        log "Switching to user $RUN_AS_USER and executing command"
        exec gosu "$RUN_AS_USER" "$@"
    else
        log "Executing command directly: $*"
        exec "$@"
    fi
fi
