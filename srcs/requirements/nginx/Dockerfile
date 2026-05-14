FROM debian:bookworm

# Install NGINX and OpenSSL
RUN apt-get update && apt-get install -y --no-install-recommends \
		nginx \
		openssl \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

# Copy NGINX configuration
COPY conf/nginx.conf /etc/nginx/sites-available/default

# Copy certificate generation script
COPY tools/generate_cert.sh /usr/local/bin/generate_cert.sh
RUN chmod +x /usr/local/bin/generate_cert.sh

# Generate TLS certificate at build time
RUN /usr/local/bin/generate_cert.sh

# Expose HTTPS port only
EXPOSE 443

# Start NGINX in foreground
CMD ["nginx", "-g", "daemon off;"]