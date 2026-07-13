# Exercise 08 — Docker Compose for Reverse Proxy

## Objective

The goal of this exercise is to learn how Docker Compose connects multiple containers on the same network.

In this setup:

* an app container serves a static HTML page
* an NGINX container acts as a reverse proxy
* Compose creates the bridge network automatically

The architecture is:

```text
Browser
	│
	│ HTTPS
	▼
NGINX container
	│
	│ HTTP
	▼
App container
```

---

## Project Structure

```text
exercise-08-compose/
├── compose.yaml
├── README.md
├── app/
│   ├── Dockerfile
│   └── index.html
└── nginx/
		├── Dockerfile
		├── nginx.conf
		└── certs/
				├── server.crt
				└── server.key
```

---

## 1. The App Service

The app service is a simple NGINX container that serves a static page.

### Dockerfile

```dockerfile
FROM nginx:alpine

COPY index.html /usr/share/nginx/html/index.html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

The page content lives in [app/index.html](app/index.html).

---

## 2. The NGINX Reverse Proxy

The NGINX container terminates TLS and forwards requests to the app container.

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

The key line is:

```text
proxy_pass http://app-container:80;
```

This works because both services are attached to the same Compose network.

---

## 3. Docker Compose

```yaml
services:
	app-container:
		build: ./app
		networks:
			- proxy-network

	nginx:
		build:
			context: ./nginx
		ports:
			- "8443:443"
		networks:
			- proxy-network
		depends_on:
			- app-container

networks:
	proxy-network:
		driver: bridge
```

Compose creates the `proxy-network` bridge network and lets the containers reach each other by service name.

---

## 4. Request Flow

```text
Browser
	│
	│ https://localhost:8443
	▼
nginx service
	│
	│ http://app-container:80
	▼
app-container service
```

The browser talks to NGINX over HTTPS, and NGINX talks to the app over plain HTTP.

---

## 5. Build and Run

Start the stack:

```bash
docker compose up --build
```

Open the site in a browser:

```text
https://localhost:8443
```

Or test it with `curl`:

```bash
curl -k https://localhost:8443
```

The `-k` flag is required because the certificate is self-signed.

