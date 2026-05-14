#!/bin/sh

CERT_DIR=/etc/ssl/certs
KEY_DIR=/etc/ssl/private

mkdir -p ${CERT_DIR} ${KEY_DIR}

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
	-keyout ${KEY_DIR}/nginx.key \
	-out ${CERT_DIR}/nginx.crt \
	-subj "/C=BE/ST=Brussels/L=Brussels/O=42School/CN=sdemey.42.fr"

echo ">> TLS certificate generated."