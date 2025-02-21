#!/bin/bash

# Generate SSH keys if they don't exist
if [ ! -f /home/airflow/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -P '' -f /home/airflow/.ssh/id_rsa
    cat /home/airflow/.ssh/id_rsa.pub >> /home/airflow/.ssh/authorized_keys
    chmod 600 /home/airflow/.ssh/authorized_keys
fi

# Execute the command passed to docker run
exec "$@"
