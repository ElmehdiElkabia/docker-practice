# Exercise 05 — NGINX with HTTPS/TLS

## Objective

The goal of this exercise is to understand how NGINX serves a website using HTTPS instead of HTTP.

In this exercise, I learned how to:

* Create a self-signed TLS certificate
* Configure NGINX to listen on port 443
* Configure TLS 1.2 and TLS 1.3
* Connect a certificate and private key to NGINX
* Run HTTPS inside a Docker container
* Publish container port 443 to host port 8443
* Test HTTPS with `curl`
* Understand why self-signed certificates are not trusted automatically

---

## Project Structure

```text
exercise-05-nginx-https/
├── Dockerfile
├── nginx.conf
├── README.md
├── certs/
│   ├── server.crt
│   └── server.key
└── html/
    └── index.html
```

---

# 1. How HTTPS Works

With normal HTTP:

```text
Client
   │
   │ Plain HTTP
   ▼
NGINX
```

The traffic is not encrypted.

With HTTPS:

```text
Client
   │
   │ TLS handshake
   ▼
NGINX
   │
   │ Certificate verification
   ▼
Encrypted connection established
   │
   ▼
HTTP request and response travel inside TLS
```

HTTPS is therefore:

```text
HTTPS = HTTP over TLS
```

TLS provides:

* Encryption
* Authentication
* Integrity

---

# 2. Create a Self-Signed Certificate

First, create the certificate directory:

```bash
mkdir -p certs
```

Then generate the private key and self-signed certificate:

```bash
openssl req -x509 -nodes -newkey rsa:2048 \
  -keyout certs/server.key \
  -out certs/server.crt \
  -days 365 \
  -subj "/C=MA/O=DockerPractice/CN=localhost" \
  -addext "subjectAltName=DNS:localhost"
```

The result is:

```text
certs/
├── server.crt
└── server.key
```

---

# 3. Understanding the OpenSSL Command

## `openssl`

Runs the OpenSSL command-line tool.

## `req`

Uses the certificate request and certificate creation functionality.

## `-x509`

Creates a self-signed X.509 certificate directly.

Without `-x509`, the command normally creates a Certificate Signing Request (CSR).

```text
Normal certificate process:

Private Key
     ↓
CSR
     ↓
Certificate Authority
     ↓
Signed Certificate
```

For this exercise:

```text
Private Key
     ↓
Self-sign
     ↓
Self-Signed Certificate
```

## `-nodes`

Creates the private key without passphrase encryption.

This is useful for this Docker exercise because NGINX must start automatically.

If the private key required a password:

```text
Container starts
      ↓
NGINX loads private key
      ↓
Password required
      ↓
Automatic startup becomes difficult
```

## `-newkey rsa:2048`

Creates a new RSA private key.

```text
-newkey    → generate a new key
rsa        → RSA algorithm
2048       → key size in bits
```

## `-keyout`

Defines where the private key is saved:

```text
certs/server.key
```

## `-out`

Defines where the certificate is saved:

```text
certs/server.crt
```

## `-days 365`

Makes the certificate valid for 365 days.

## `-subj`

Defines the certificate subject without interactive questions.

```text
C  = Country
O  = Organization
CN = Common Name
```

The Common Name is:

```text
localhost
```

because the server is accessed using:

```text
https://localhost:8443
```

## `-addext "subjectAltName=DNS:localhost"`

Adds `localhost` as a Subject Alternative Name.

Modern clients verify hostnames using the Subject Alternative Name extension.

---

# 4. Certificate vs Private Key

## `server.crt`

The certificate is public.

It contains:

* Server identity information
* Public key
* Validity period
* Issuer information

NGINX sends the certificate to the client during the TLS handshake.

## `server.key`

The private key is secret.

NGINX uses it during TLS authentication and cryptographic operations.

```text
server.key
    │
    │ Mathematically related
    ▼
server.crt
```

The private key must never be shared publicly in a real production environment.

The certificate can be public.

---

# 5. Dockerfile

```dockerfile
FROM nginx:alpine

RUN rm /etc/nginx/conf.d/default.conf

COPY nginx.conf /etc/nginx/conf.d/default.conf

COPY certs/ /etc/ssl/certs/

COPY html/ /var/www/html/

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]
```

---

# 6. Understanding the Dockerfile

## `FROM nginx:alpine`

Uses the official NGINX image based on Alpine Linux.

The image already contains:

* NGINX
* NGINX entrypoint scripts
* Required runtime dependencies

---

## Remove the Default Configuration

```dockerfile
RUN rm /etc/nginx/conf.d/default.conf
```

The official image already contains a default server configuration.

This command removes it so that I can use my own configuration.

---

## Copy the NGINX Configuration

```dockerfile
COPY nginx.conf /etc/nginx/conf.d/default.conf
```

Copies my local NGINX configuration into the image.

```text
Host
nginx.conf

    ↓ COPY

Container Image
/etc/nginx/conf.d/default.conf
```

---

## Copy the TLS Files

```dockerfile
COPY certs/ /etc/ssl/certs/
```

This creates:

```text
/etc/ssl/certs/server.crt
/etc/ssl/certs/server.key
```

inside the image.

These paths must match the paths configured in `nginx.conf`.

---

## Copy the Website

```dockerfile
COPY html/ /var/www/html/
```

This copies:

```text
html/index.html
```

to:

```text
/var/www/html/index.html
```

inside the image.

---

## `EXPOSE 443`

```dockerfile
EXPOSE 443
```

Documents that the container is expected to receive traffic on port 443.

It does not publish the port to the host.

The actual port mapping is created with:

```bash
-p 8443:443
```

---

## Keep NGINX in the Foreground

```dockerfile
CMD ["nginx", "-g", "daemon off;"]
```

Normally, NGINX can run as a background daemon.

Inside Docker, the main process must stay in the foreground.

```text
Container starts
      ↓
NGINX starts as PID 1
      ↓
NGINX remains running
      ↓
Container remains running
```

If NGINX exits:

```text
NGINX stops
      ↓
Main container process stops
      ↓
Container stops
```

---

# 7. NGINX Configuration

```nginx
server {
    listen 443 ssl;

    server_name localhost;

    ssl_certificate /etc/ssl/certs/server.crt;
    ssl_certificate_key /etc/ssl/certs/server.key;

    ssl_protocols TLSv1.2 TLSv1.3;

    root /var/www/html;

    location / {
        index index.html;
    }
}
```

---

# 8. Understanding the NGINX Configuration

## `server`

```nginx
server {
}
```

Defines one virtual HTTP/HTTPS server.

The directives inside this block describe how this server receives and handles requests.

---

## `listen 443 ssl`

```nginx
listen 443 ssl;
```

This tells NGINX:

```text
Listen on TCP port 443
        +
Use TLS/SSL for connections
```

Without `ssl`, NGINX would not treat the connection as HTTPS.

---

## `server_name localhost`

```nginx
server_name localhost;
```

Defines the hostname associated with this server block.

For this exercise, the request is sent to:

```text
https://localhost:8443
```

---

## `ssl_certificate`

```nginx
ssl_certificate /etc/ssl/certs/server.crt;
```

Tells NGINX where to find the public certificate.

NGINX sends this certificate to clients during the TLS handshake.

---

## `ssl_certificate_key`

```nginx
ssl_certificate_key /etc/ssl/certs/server.key;
```

Tells NGINX where to find the private key associated with the certificate.

The certificate and private key must be a matching pair.

---

## `ssl_protocols`

```nginx
ssl_protocols TLSv1.2 TLSv1.3;
```

Allows only TLS 1.2 and TLS 1.3.

```text
TLS 1.0  → disabled
TLS 1.1  → disabled
TLS 1.2  → allowed
TLS 1.3  → allowed
```

Older TLS versions should not be used.

---

## `root`

```nginx
root /var/www/html;
```

Defines where NGINX looks for website files.

For example:

```text
Request:
GET /index.html

        ↓

Filesystem:
/var/www/html/index.html
```

---

## `location /`

```nginx
location / {
    index index.html;
}
```

Matches requests beginning with `/`.

For example:

```text
/
/hello
/about
/images/logo.png
```

The `index` directive defines the default file used for a directory request.

A request to:

```text
/
```

can therefore serve:

```text
/var/www/html/index.html
```

---

# 9. Build the Docker Image

```bash
docker build -t my-nginx-https:v1 .
```

The process is:

```text
Dockerfile
     ↓
Base NGINX image
     ↓
Remove default configuration
     ↓
Copy custom configuration
     ↓
Copy certificate and private key
     ↓
Copy website
     ↓
Create final image
```

---

# 10. Run the Container

```bash
docker run -d \
  --name nginx-https \
  -p 8443:443 \
  my-nginx-https:v1
```

The port mapping is:

```text
Host                     Container

localhost:8443  ───────► 443
                           │
                           ▼
                         NGINX
```

Port `8443` is used on the host because this is a development exercise.

NGINX still listens on the standard HTTPS port `443` inside the container.

---

# 11. Test Without `-k`

```bash
curl https://localhost:8443
```

The request fails because the certificate is self-signed.

The client does not trust the certificate automatically.

Normal trusted certificate chain:

```text
Server Certificate
        ↓
Intermediate CA
        ↓
Trusted Root CA
        ↓
Already trusted by operating system
```

This exercise:

```text
Self-Signed Certificate
        ↓
No trusted Certificate Authority
        ↓
curl rejects it
```

---

# 12. Test With `-k`

```bash
curl -k https://localhost:8443
```

The `-k` option means:

```text
--insecure
```

It tells `curl` not to verify the authenticity of the server certificate.

The TLS connection is still encrypted, but certificate verification is disabled.

This is acceptable for a local learning exercise but should not be used as a normal production solution.

---

# 13. Inspect the TLS Connection

```bash
curl -vk https://localhost:8443
```

Options:

```text
-v → verbose output
-k → ignore certificate verification errors
```

The output shows information about:

* TCP connection
* TLS handshake
* Negotiated TLS version
* Certificate
* HTTP request
* HTTP response

---

# 14. Test TLS 1.2

```bash
curl -k --tlsv1.2 --tls-max 1.2 https://localhost:8443
```

This forces the connection to use only TLS 1.2.

The connection should succeed because NGINX allows:

```nginx
ssl_protocols TLSv1.2 TLSv1.3;
```

---

# 15. Test TLS 1.3

```bash
curl -k --tlsv1.3 https://localhost:8443
```

The connection should succeed because TLS 1.3 is enabled.

---

# 16. Why Does the Container Stop if NGINX Stops?

The main container process is:

```text
nginx
```

The lifecycle is:

```text
Docker starts container
        ↓
CMD starts NGINX
        ↓
NGINX runs in foreground
        ↓
Container stays alive
```

If NGINX crashes or exits:

```text
NGINX exits
      ↓
PID 1 exits
      ↓
Container stops
```

A container normally lives as long as its main process lives.

---

# 17. Error I Encountered

NGINX failed with:

```text
cannot load certificate
No such file or directory
```

The reason was a path mismatch.

The Dockerfile copied the certificate to one path, but `nginx.conf` searched for another path.

Incorrect relationship:

```text
Dockerfile:
COPY certs/ /etc/ssl/certs/

NGINX:
ssl_certificate /etc/nginx/ssl/nginx.crt;
```

Correct relationship:

```text
Dockerfile:
COPY certs/ /etc/ssl/certs/

NGINX:
ssl_certificate /etc/ssl/certs/server.crt;
ssl_certificate_key /etc/ssl/certs/server.key;
```

The important lesson is:

```text
Docker COPY destination
          ↓
Must exactly match
          ↓
Path used in nginx.conf
```

---

# 18. Why Rebuilding Was Necessary

Changing a local file does not automatically modify an existing image or container.

```text
Local nginx.conf changed
        ↓
Old image remains unchanged
        ↓
Old container remains unchanged
```

Running:

```bash
docker start nginx-https
```

only restarts the same old container.

The correct workflow after changing the Dockerfile or configuration is:

```bash
docker rm -f nginx-https

docker build -t my-nginx-https:v2 .

docker run -d \
  --name nginx-https \
  -p 8443:443 \
  my-nginx-https:v2
```

---

# Final Request Flow

```text
curl
  │
  │ https://localhost:8443
  ▼
Host port 8443
  │
  │ Docker port mapping
  ▼
Container port 443
  │
  ▼
NGINX
  │
  ├── Loads server.crt
  ├── Loads server.key
  ├── Accepts TLS 1.2 or TLS 1.3
  │
  ▼
TLS connection established
  │
  ▼
NGINX processes GET /
  │
  ▼
location /
  │
  ▼
root /var/www/html
  │
  ▼
index.html
  │
  ▼
Encrypted HTTPS response
  │
  ▼
curl
```

---

# Questions and Answers

## What is HTTPS?

HTTPS is HTTP communication protected by TLS.

## What is TLS?

TLS is a protocol that provides encryption, authentication, and integrity for network communication.

## What is the difference between `server.crt` and `server.key`?

`server.crt` is the public certificate sent to clients.

`server.key` is the private key and must remain secret.

## Why does normal `curl` reject the certificate?

Because the certificate is self-signed and is not trusted by a Certificate Authority in the client's trust store.

## What does `curl -k` do?

It disables certificate verification.

The connection can still be encrypted, but the client no longer verifies that it is communicating with a trusted server.

## Why use `8443:443`?

Port `8443` is the host port.

Port `443` is the container port where NGINX listens.

```text
Host 8443 → Container 443
```

## Does `EXPOSE 443` publish the port?

No.

`EXPOSE` documents the intended container port.

The `-p` option publishes the port.

## What happens if NGINX cannot read the private key?

NGINX fails to start, the main process exits, and the container stops.

## Why does NGINX run with `daemon off;`?

Because the main process must stay in the foreground to keep the Docker container running.

---

# What I Learned

After completing this exercise, I understand:

* HTTPS is HTTP protected by TLS.
* NGINX can terminate TLS connections.
* A certificate and private key work together.
* The private key must remain secret.
* Self-signed certificates are useful for local development.
* Self-signed certificates are not trusted automatically.
* `curl -k` disables certificate verification.
* NGINX listens on port 443 for HTTPS.
* Docker can map host port 8443 to container port 443.
* `EXPOSE` does not publish a port.
* TLS 1.2 and TLS 1.3 can be explicitly allowed.
* Dockerfile paths and NGINX configuration paths must match exactly.
* Changing a local configuration requires rebuilding the image and recreating the container.
* A Docker container stops when its main process exits.
