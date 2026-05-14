FROM debian:bookworm
# penultimate stable = bookworm (Debian 12)

# Install MariaDB server
RUN apt-get update && apt-get install -y --no-install-recommends \
		mariadb-server \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

# Copy configuration file with high priority so it overrides default 50-server.cnf
COPY conf/my.cnf /etc/mysql/mariadb.conf.d/99-custom.cnf

# Copy initialization script
COPY tools/db_init.sh /usr/local/bin/db_init.sh
RUN chmod +x /usr/local/bin/db_init.sh

# Expose MySQL port (internal network only)
EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/db_init.sh"]