#!/bin/bash

# Function for logging
log() {
    echo "$(date "+%Y-%m-%d %H:%M:%S") - $1"
}

log "Starting service with SERVICE_TYPE=$SERVICE_TYPE"

if [ "$SERVICE_TYPE" = "hadoop" ]; then
    log "Starting Hadoop service"
    /bootstrap.sh "$@"
elif [ "$SERVICE_TYPE" = "spark" ]; then
    log "Starting Spark service"
    /spark-entrypoint.sh "$@"
else
    log "No specific service type specified, executing command directly"
    exec "$@"
fi
