#!/bin/bash

echo "Generating self-signed SSL certificate for Nginx..."

echo "Going to /etc/ssl directory..."
cd /etc/ssl

echo "creating certs directory..."
mkdir -p certs

echo "Generating SSL certificate..."
openssl req -x509 -nodes -newkey rsa:2048 \
  -keyout certs/server.key \
  -out certs/server.crt \
  -days 365 \
  -subj "/C=MA/O=DockerPractice/CN=localhost" \
  -addext "subjectAltName=DNS:localhost"

echo "SSL certificate generated successfully."

echo "Starting Nginx server..."
# Start Nginx in the foreground
nginx -g "daemon off;"