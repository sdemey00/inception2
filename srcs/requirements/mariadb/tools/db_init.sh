#!/bin/sh
set -e

# Read secrets
MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
MYSQL_USER_PASSWORD=$(cat /run/secrets/db_password)

# Use environment variables
MYSQL_DATABASE=${MYSQL_DATABASE:-wordpress}
MYSQL_USER=${MYSQL_USER:-wp_user}

# During bootstrap MariaDB runs with --skip-networking, so force socket usage.
unset MYSQL_HOST MYSQL_TCP_PORT
export MYSQL_UNIX_PORT=/run/mysqld/mysqld.sock
MYSQL_LOCAL_OPTS="--socket=/run/mysqld/mysqld.sock -u root"

# Create runtime dirs
mkdir -p /var/run/mysqld /var/log/mysql
chown -R mysql:mysql /var/run/mysqld /var/log/mysql /var/lib/mysql

# Check if initialization is needed
if [ ! -f "/var/lib/mysql/.initialized" ]; then
    echo ">> Initializing MariaDB..."
    
    # Start MariaDB in background without networking first
    mariadbd --user=mysql --skip-networking &
    PID=$!
    
    # Wait until local socket accepts admin commands.
    until mysqladmin ${MYSQL_LOCAL_OPTS} ping --silent >/dev/null 2>&1; do
        sleep 1
    done
    
    # Set root password and initialize database
    mysql ${MYSQL_LOCAL_OPTS} -e "
    ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
    CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
    CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_USER_PASSWORD}';
    GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
    FLUSH PRIVILEGES;
    "
    
    # Shutdown the temp instance
    mysqladmin ${MYSQL_LOCAL_OPTS} -p"${MYSQL_ROOT_PASSWORD}" shutdown
    wait $PID
    
    # Mark initialization as complete
    touch /var/lib/mysql/.initialized
    echo ">> MariaDB initialization complete"
fi

# Start MariaDB normally
exec mariadbd --user=mysql
