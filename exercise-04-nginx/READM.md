# Exercise 04 — NGINX with Docker

## Objective

The goal of this exercise is to understand:

* What NGINX is
* How NGINX runs inside a Docker container
* How Docker port mapping works
* How NGINX serves static files
* The difference between `nginx.conf` and `conf.d/default.conf`
* How NGINX configuration contexts work

---

## Project Structure

```text
exercise-04-nginx/
├── Dockerfile
├── nginx.conf
├── README.md
└── html/
    └── index.html
```

---

## Requirements

Create an NGINX container that:

1. Uses `nginx:alpine`.
2. Uses a custom NGINX server configuration.
3. Serves a custom `index.html`.
4. Stores the website in `/var/www/html/`.
5. Exposes the NGINX port.
6. Runs NGINX in the foreground.

---

## Dockerfile

```dockerfile
FROM nginx:alpine

RUN rm /etc/nginx/conf.d/default.conf

COPY nginx.conf /etc/nginx/conf.d/default.conf

COPY html/ /var/www/html/

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

---

## nginx.conf

```nginx
server {
    listen 80;

    root /var/www/html;

    location / {
        index index.html;
    }

    location /health {
        return 200 "OK\n";
    }
}
```

---

## Build the Image

```bash
docker build -t my-nginx .
```

---

## Create and Run a Container

```bash
docker run --name test_v1 -p 8080:80 my-nginx
```

Open:

```text
http://localhost:8080
```

Test the health endpoint:

```bash
curl http://localhost:8080/health
```

Expected output:

```text
OK
```

---

## Start an Existing Container

If the container already exists:

```bash
docker start test_v1
```

Start it and attach to its output:

```bash
docker start -a test_v1
```

View its logs:

```bash
docker logs test_v1
```

---

## Questions and Answers

### 1. What is NGINX?

NGINX is a web server.

In this exercise, its job is:

```text
Receive HTTP request
        ↓
Find the requested resource
        ↓
Read the file from /var/www/html
        ↓
Send the response to the browser
```

NGINX can also work as:

* A reverse proxy
* A load balancer
* A TLS/HTTPS endpoint

For now, this exercise focuses on the web server role.

---

### 2. What does `listen 80;` mean?

```nginx
listen 80;
```

means that NGINX listens for connections on port `80` inside the container.

---

### 3. What does `-p 8080:80` mean?

```bash
docker run -p 8080:80 my-nginx
```

The format is:

```text
HOST_PORT:CONTAINER_PORT
```

Therefore:

```text
Browser
   ↓
localhost:8080
   ↓
Docker port mapping
   ↓
Container port 80
   ↓
NGINX
```

Port `8080` belongs to the host machine.

Port `80` belongs to the container.

---

### 4. What does `root` do?

```nginx
root /var/www/html;
```

It tells NGINX where the website files are located.

For a request to:

```text
/
```

NGINX can serve:

```text
/var/www/html/index.html
```

---

### 5. What is a `location` block?

A `location` block defines how NGINX handles a request path.

Example:

```nginx
location / {
    index index.html;
}
```

This handles requests to the website root.

Another example:

```nginx
location /health {
    return 200 "OK\n";
}
```

A request to `/health` returns:

```text
OK
```

without reading an HTML file.

---

### 6. Why does NGINX use `daemon off;` in Docker?

Normally, NGINX can run in the background as a daemon.

Docker containers should keep their main process running in the foreground.

```bash
nginx -g "daemon off;"
```

keeps NGINX as the main container process.

If the main process stops, the container stops.

---

### 7. What is the difference between `nginx.conf` and `default.conf`?

The main configuration file is:

```text
/etc/nginx/nginx.conf
```

It contains the global NGINX configuration.

Its structure is similar to:

```nginx
events {
}

http {
    include /etc/nginx/conf.d/*.conf;
}
```

The file:

```text
/etc/nginx/conf.d/default.conf
```

normally contains a `server {}` block.

The hierarchy is:

```text
nginx.conf
└── http {}
    └── server {}
        └── location {}
```

---

### 8. Why did this configuration fail in `/etc/nginx/nginx.conf`?

This is invalid as the entire main configuration:

```nginx
server {
    listen 80;
}
```

NGINX reports:

```text
"server" directive is not allowed here
```

because `server {}` must be inside the `http {}` context.

A valid complete main configuration is:

```nginx
events {
}

http {
    server {
        listen 80;

        root /var/www/html;

        location / {
            index index.html;
        }
    }
}
```

---

### 9. What is the best practice for this exercise?

Keep the official main configuration:

```text
/etc/nginx/nginx.conf
```

and replace only:

```text
/etc/nginx/conf.d/default.conf
```

This allows the official image to keep its global NGINX configuration while the project controls only the application server configuration.

Use:

```dockerfile
COPY nginx.conf /etc/nginx/conf.d/default.conf
```

Replace the full `/etc/nginx/nginx.conf` only when global NGINX configuration needs to be controlled.

---

### 10. What is the difference between `docker run` and `docker start`?

`docker run` creates a new container from an image:

```bash
docker run --name test_v1 my-nginx
```

`docker start` starts an existing stopped container:

```bash
docker start test_v1
```

The relationship is:

```text
Dockerfile
    ↓ docker build
Image
    ↓ docker run
Container
    ↓ docker start / stop
Same container
```

---

### 11. How do I test the NGINX configuration?

Inside the image:

```bash
docker run --rm my-nginx nginx -t
```

For a running container:

```bash
docker exec test_v1 nginx -t
```

A successful test should report that the configuration syntax is valid.

---

## What I Learned

After this exercise, I understand:

* NGINX can serve static files
* NGINX listens on a port inside the container
* Docker maps a host port to a container port
* `server {}` belongs inside the `http {}` context
* `location {}` belongs inside `server {}`
* The official NGINX image loads configuration files from `conf.d`
* `docker run` creates a container
* `docker start` restarts an existing container
* NGINX must stay in the foreground inside Docker
