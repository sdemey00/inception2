#!/bin/sh
set -e

# Read secrets
MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
MYSQL_USER_PASSWORD=$(cat /run/secrets/db_password)

# Use environment variables or defaults
MYSQL_DATABASE=${MYSQL_DATABASE:-wordpress}
MYSQL_USER=${MYSQL_USER:-wp_user}

# Create runtime dirs
mkdir -p /var/run/mysqld /var/log/mysql
chown -R mysql:mysql /var/run/mysqld /var/log/mysql /var/lib/mysql

# Initialize database if missing
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo ">> First run: creating database and users..."
    
    # Start temporary server
    mysqld --user=mysql --skip-networking &
    TEMP_PID=$!

    # Wait for server to be ready
    while ! mysqladmin ping --silent 2>/dev/null; do
        sleep 0.5
    done

    # Initialize database and users
    mysql -u root <<EOSQL
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_USER_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOSQL

    # Shutdown temp server
    mysqladmin -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown

    echo ">> MariaDB initialization complete."
fi

# Start MariaDB in foreground as PID 1
exec mysqld_safe --user=mysql
