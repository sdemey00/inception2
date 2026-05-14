FROM debian:bookworm
# penultimate stable = bookworm (Debian 12)

# Install PHP-FPM, WordPress dependencies, and WP-CLI prerequisites
RUN apt-get update && apt-get install -y --no-install-recommends \
		ca-certificates \
		php8.2-fpm \
		php8.2-mysql \
		php8.2-curl \
		php8.2-gd \
		php8.2-intl \
		php8.2-zip \
		php8.2-xml \
		php8.2-mbstring \
		wget \
		curl \
		mariadb-client \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

# Install WP-CLI (WordPress command-line tool)
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
	&& chmod +x wp-cli.phar \
	&& mv wp-cli.phar /usr/local/bin/wp

# Copy PHP-FPM pool configuration
COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf

# Copy WordPress setup script
COPY tools/wp_setup.sh /usr/local/bin/wp_setup.sh
RUN chmod +x /usr/local/bin/wp_setup.sh

# WordPress files will be served from this directory
WORKDIR /var/www/html

# PHP-FPM listens on port 9000
EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/wp_setup.sh"]