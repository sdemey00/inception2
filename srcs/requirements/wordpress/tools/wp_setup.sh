#!/bin/sh
set -e

WP_PATH=/var/www/html

# Read secrets
DB_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/credentials)

# Wait for MariaDB to be ready
echo ">> Waiting for MariaDB..."
while ! mysqladmin ping -h"${MYSQL_HOST}" -u"${MYSQL_USER}" \
	-p"${DB_PASSWORD}" --silent 2>/dev/null; do
	sleep 2
done
echo ">> MariaDB is ready."

# Download and configure WordPress only if not already installed
if [ ! -f "${WP_PATH}/wp-config.php" ]; then
	echo ">> Installing WordPress..."
	
	mkdir -p ${WP_PATH}
	
	# Download WordPress
	wp core download --path=${WP_PATH} --allow-root
	
	# Create wp-config.php
	wp config create \
		--path=${WP_PATH} \
		--dbname=${MYSQL_DATABASE} \
		--dbuser=${MYSQL_USER} \
		--dbpass=${DB_PASSWORD} \
		--dbhost=mariadb:3306 \
		--allow-root
	
	# Install WordPress core
	wp core install \
		--path=${WP_PATH} \
		--url=https://${DOMAIN_NAME} \
		--title="Inception" \
		--admin_user=${WP_ADMIN_USER} \
		--admin_password=${WP_ADMIN_PASSWORD} \
		--admin_email=${WP_ADMIN_EMAIL} \
		--skip-email \
		--allow-root

	# Create a second (non-admin) user
	wp user create \
		${WP_USER} ${WP_USER_EMAIL} \
		--role=editor \
		--user_pass=${WP_ADMIN_PASSWORD} \
		--path=${WP_PATH} \
		--allow-root

fi

# Fix permissions
chown -R www-data:www-data ${WP_PATH}
chmod -R 755 ${WP_PATH}

echo ">> Starting PHP-FPM..."
# Start php-fpm in foreground as PID 1
# The '-F' flag keeps php-fpm in the foreground
exec php-fpm8.2 -F