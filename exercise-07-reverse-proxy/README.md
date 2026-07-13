# Exercise 07 — Reverse Proxy with NGINX

## Objective

The goal of this exercise is to understand how NGINX can act as a reverse proxy in front of an application container.

In this setup:

* the browser talks to the NGINX container over HTTPS
* NGINX terminates TLS on port 443
* NGINX forwards requests to the app container on port 80

The architecture is:

```text
Client
	│
	│ HTTPS
	▼
NGINX reverse proxy
	│
	│ HTTP
	▼
App container
```

---

## Project Structure

```text
exercise-07-reverse-proxy/
├── app/
│   ├── Dockerfile
│   └── index.html
├── nginx/
│   ├── Dockerfile
│   ├── nginx.conf
│   └── certs/
│       ├── server.crt
│       └── server.key
└── README.md
```

---

## 1. The App Container

The app container is a simple NGINX container that serves a static HTML page.

### Dockerfile

```dockerfile
FROM nginx:alpine

COPY index.html /usr/share/nginx/html/index.html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

The file served by the app container is [app/index.html](app/index.html).

---

## 2. The Reverse Proxy Container

The reverse proxy container uses NGINX to expose HTTPS to the outside world and forward traffic to the app container.

### Dockerfile

```dockerfile
FROM nginx:alpine

RUN rm /etc/nginx/conf.d/default.conf

COPY nginx.conf /etc/nginx/conf.d/default.conf

COPY certs/ /etc/ssl/certs/

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]
```

### NGINX Configuration

```nginx
server {
		listen 443 ssl;

		ssl_certificate /etc/ssl/certs/server.crt;
		ssl_certificate_key /etc/ssl/certs/server.key;

		ssl_protocols TLSv1.2 TLSv1.3;

		location / {
				proxy_pass http://app-container:80;
		}
}
```

The important line is:

```text
proxy_pass http://app-container:80;
```

This tells NGINX to forward incoming requests to the application container by container name.

---

## 3. How the Request Flows

The request path is:

```text
Browser
	│
	│ https://localhost:8443
	▼
NGINX reverse proxy
	│
	│ http://app-container:80
	▼
App container
	│
	▼
HTML response
```

NGINX handles TLS termination, so the app container only needs to serve plain HTTP.

---

## 4. Certificates

The reverse proxy container includes a certificate and private key under `nginx/certs/`.

* `server.crt` is the public certificate
* `server.key` is the private key

NGINX uses them to enable HTTPS on port 443.

---

## 5. Build and Run

Build the app image:

```bash
docker build -t reverse-proxy-app ./app
```

Build the reverse proxy image:

```bash
docker build -t reverse-proxy-nginx ./nginx
```

Run the app container on the same Docker network as NGINX:

```bash
docker run -d \
	--name app-container \
	--network app-network \
	reverse-proxy-app
```

Run the NGINX container and publish HTTPS to the host:

```bash
docker run -d \
	--name nginx-container \
	--network app-network \
	-p 8443:443 \
	reverse-proxy-nginx
```

---

## 6. Test the Setup

Open the site in a browser:

```text
https://localhost:8443
```

Or test it with `curl`:

```bash
curl -k https://localhost:8443
```

The `-k` flag is needed because the certificate is self-signed.

---

## 7. What This Exercise Teaches

This exercise shows how to:

* separate public traffic from internal application traffic
* use NGINX as a reverse proxy
* terminate TLS at the proxy layer
* route requests between containers using container names
* keep the application container simple

