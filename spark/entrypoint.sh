#!/bin/bash

# Function for logging
log() {
    echo "$(date "+%Y-%m-%d %H:%M:%S") - $1"
}

# Set secure permissions
umask 077

log "Starting container initialization"

# Check if we're running as root and should drop privileges
if [ "$(id -u)" -eq 0 ] && [ -n "$RUN_AS_USER" ]; then
    log "Container started as root, will switch to user $RUN_AS_USER"
    
    # Create user if it doesn't exist
    if ! id -u "$RUN_AS_USER" &>/dev/null; then
        log "Creating user $RUN_AS_USER"
        useradd -m -s /bin/bash "$RUN_AS_USER"
    fi
fi

# Generate SSH keys if they don't exist
if [ ! -f /home/airflow/.ssh/id_rsa ]; then
    log "Generating SSH keys"
    
    # Create directory with secure permissions
    mkdir -p /home/airflow/.ssh
    
    # Generate a more secure key (RSA 4096 bits)
    ssh-keygen -t rsa -b 4096 -P '' -f /home/airflow/.ssh/id_rsa -C "airflow@$(hostname)"
    
    # Secure the authorized_keys file
    cat /home/airflow/.ssh/id_rsa.pub >> /home/airflow/.ssh/authorized_keys
    chmod 600 /home/airflow/.ssh/authorized_keys
    chmod 700 /home/airflow/.ssh
    
    # Set proper ownership
    chown -R airflow:airflow /home/airflow/.ssh
    
    # Configure SSH to be more secure
    cat > /home/airflow/.ssh/config << EOF
Host *
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    LogLevel ERROR
    HashKnownHosts yes
    PasswordAuthentication no
    PubkeyAuthentication yes
    HostKeyAlgorithms ssh-ed25519,ssh-rsa
    KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256
    Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
    MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
EOF
    chmod 600 /home/airflow/.ssh/config
    chown airflow:airflow /home/airflow/.ssh/config
    
    log "SSH key generation complete"
fi

# Check for any security vulnerabilities
if command -v apt-get &> /dev/null && [ "$(id -u)" -eq 0 ]; then
    log "Checking for security updates"
    apt-get update -qq &> /dev/null
    security_updates=$(apt-get upgrade -s | grep -i security | wc -l)
    if [ "$security_updates" -gt 0 ]; then
        log "WARNING: $security_updates security updates available. Consider updating the container."
    fi
fi

# Drop privileges if running as root and RUN_AS_USER is specified
if [ "$(id -u)" -eq 0 ] && [ -n "$RUN_AS_USER" ]; then
    log "Switching to user $RUN_AS_USER and executing command"
    exec gosu "$RUN_AS_USER" "$@"
else
    # Execute the command passed to docker run
    log "Executing command: $*"
    exec "$@"
fi
