# Exercise 06 — Two Containers on One Docker Network

## Objective

The goal of this exercise is to understand how two Docker containers communicate through a user-defined Docker network.

The architecture is:

```text
Docker Host
    │
    └── app-network
          │
          ├── nginx-container
          │
          └── web-container
```

The main concept is:

```text
nginx-container
      │
      │ http://web-container:80
      ▼
web-container
```

The containers communicate using the container name instead of an IP address or `localhost`.

---

# Project Structure

```text
exercise-06-docker-network/
├── nginx/
│   ├── Dockerfile
│   └── nginx.conf
├── web/
│   ├── Dockerfile
│   └── index.html
└── README.md
```

---

# 1. Create the Docker Network

```bash
docker network create app-network
```

This creates a user-defined bridge network.

Check available networks:

```bash
docker network ls
```

Inspect the network:

```bash
docker network inspect app-network
```

Before starting containers, the network contains no connected containers.

```text
app-network
└── no containers
```

---

# 2. The Web Container

The web container serves `index.html`.

## Dockerfile

```dockerfile
FROM nginx:alpine

COPY index.html /usr/share/nginx/html/index.html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

The container uses NGINX as a simple web server.

Its job is:

```text
HTTP request
      ↓
web-container:80
      ↓
NGINX
      ↓
index.html
      ↓
HTTP response
```

Build the image:

```bash
docker build -t simple-web:v1 ./web
```

Run the container:

```bash
docker run -d \
  --name web-container \
  --network app-network \
  simple-web:v1
```

Notice that I did not use:

```text
-p
```

The web container does not need to be directly accessible from the host.

It only needs to communicate with other containers on `app-network`.

---

# 3. The NGINX Container

## Dockerfile

```dockerfile
FROM nginx:alpine

RUN rm /etc/nginx/conf.d/default.conf

COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

## NGINX Configuration

```nginx
server {
    listen 80;

    location / {
        return 200 "Hello from NGINX container!\n";
    }
}
```

Build the image:

```bash
docker build -t network-nginx:v1 ./nginx
```

Run the container:

```bash
docker run -d \
  --name nginx-container \
  --network app-network \
  -p 8080:80 \
  network-nginx:v1
```

The architecture is now:

```text
Host
 │
 │ localhost:8080
 ▼
nginx-container:80
       │
       │ app-network
       │
       ▼
web-container:80
```

Both containers are connected to the same Docker network.

---

# 4. Inspect the Network

```bash
docker network inspect app-network
```

The network now contains:

```text
app-network
├── nginx-container
└── web-container
```

Each container has its own internal IP address.

Example:

```text
nginx-container → 172.x.x.x
web-container   → 172.x.x.x
```

These IP addresses should not be hardcoded because Docker can assign different addresses when containers are recreated.

Container names are more useful:

```text
web-container
nginx-container
```

---

# 5. Test Communication Between Containers

Enter the NGINX container:

```bash
docker exec -it nginx-container sh
```

From inside the container:

```bash
wget -qO- http://web-container
```

The request path is:

```text
nginx-container
      │
      │ asks for "web-container"
      ▼
Docker DNS
      │
      │ resolves the name
      ▼
web-container IP
      │
      ▼
TCP port 80
      │
      ▼
NGINX in web-container
      │
      ▼
index.html
```

The expected response is the content of:

```text
web/index.html
```

This proves that the containers can communicate.

---

# 6. Why Does the Container Name Work?

The request is:

```text
http://web-container
```

`web-container` is a hostname.

Docker provides DNS-based name resolution for containers connected to the same user-defined network.

Conceptually:

```text
nginx-container:

"Where is web-container?"
          │
          ▼
     Docker DNS
          │
          ▼
"web-container is at 172.x.x.x"
          │
          ▼
      HTTP request
```

Therefore, I do not need to know the container's IP address.

---

# 7. Test Docker DNS

From inside `nginx-container`:

```bash
getent hosts web-container
```

The result shows the IP address associated with the name:

```text
172.x.x.x    web-container
```

The important concept is:

```text
Container name
      ↓
Docker DNS
      ↓
Container IP
```

---

# 8. Why Does `localhost` Fail?

From inside `nginx-container`, this is wrong:

```text
http://localhost:80
```

Inside a container:

```text
localhost
    ↓
the current container itself
```

Therefore:

```text
Inside nginx-container:

localhost = nginx-container
```

It does not mean:

```text
localhost = web-container
```

Each container has its own network namespace.

```text
nginx-container
├── its own localhost
└── its own network interfaces

web-container
├── its own localhost
└── its own network interfaces
```

The correct address is:

```text
http://web-container:80
```

---

# 9. Why Does the Web Container Not Need `-p`?

The web container is not accessed directly from the host.

The communication happens internally:

```text
nginx-container
      │
      │ app-network
      ▼
web-container
```

Publishing a port is only necessary when something outside Docker needs to access the container.

For example:

```text
Host
  │
  │ requires -p
  ▼
Container
```

But container-to-container communication on the same network does not require published host ports.

---

# 10. Internal Port vs Published Port

## Internal Container Port

```text
web-container:80
```

This is used by containers communicating through the Docker network.

## Published Host Port

```text
localhost:8080
```

Created with:

```bash
-p 8080:80
```

The mapping is:

```text
Host port 8080
       ↓
Container port 80
```

Therefore:

```text
Container-to-container:

web-container:80
```

and:

```text
Host-to-container:

localhost:8080
```

are different communication paths.

---

# 11. Why Use a Container Name Instead of an IP Address?

Container IP addresses can change.

For example:

```text
First run:

web-container → 172.18.0.2
```

After recreation:

```text
Second run:

web-container → 172.18.0.5
```

Hardcoding this is fragile:

```text
http://172.18.0.2
```

Using the name is better:

```text
http://web-container
```

Docker resolves the current address automatically.

---

# 12. What Happens on Different Networks?

Suppose:

```text
network-A
└── nginx-container

network-B
└── web-container
```

The containers do not share the same network.

The NGINX container normally cannot reach the web container using:

```text
web-container
```

For direct communication, they need a shared network:

```text
app-network
├── nginx-container
└── web-container
```

---

# 13. Questions and Answers

## What is a Docker network?

A Docker network provides network connectivity between containers.

A user-defined network allows connected containers to communicate and discover each other by name.

## Why can the two containers communicate?

Because both containers are connected to:

```text
app-network
```

## Why does `web-container` work as a hostname?

Docker provides name resolution for containers connected to the same user-defined network.

## What is Docker DNS?

Docker provides DNS-based name resolution that converts a container name into its current network IP address.

```text
web-container
      ↓
Docker DNS
      ↓
172.x.x.x
```

## Why does `localhost` fail?

Because `localhost` always refers to the current container.

Inside `nginx-container`:

```text
localhost = nginx-container
```

## Why does the web container not need `-p`?

Because only another container needs to access it through the Docker network.

It does not need direct access from the host.

## What is the difference between an internal port and a published port?

An internal port is used inside Docker networking.

A published port makes a container accessible from the host.

## Why use a container name instead of an IP?

Container IP addresses can change.

The container name remains a stable address that Docker can resolve.

## What happens if the containers are on different networks?

They cannot normally discover and communicate with each other unless they share another network.

---

# Final Mental Model

```text
Docker Host
    │
    └── app-network
          │
          ├── nginx-container
          │         │
          │         │ http://web-container
          │         ▼
          └── web-container:80
                    │
                    ▼
                  NGINX
                    │
                    ▼
                index.html
```

The most important lesson is:

```text
Same Docker network
        +
Container name
        +
Internal port

        ↓

Container-to-container communication
```

---

# Commands Used

```bash
# Create network
docker network create app-network

# Inspect networks
docker network ls
docker network inspect app-network

# Build web image
docker build -t simple-web:v1 ./web

# Run web container
docker run -d \
  --name web-container \
  --network app-network \
  simple-web:v1

# Build NGINX image
docker build -t network-nginx:v1 ./nginx

# Run NGINX container
docker run -d \
  --name nginx-container \
  --network app-network \
  -p 8080:80 \
  network-nginx:v1

# Enter NGINX container
docker exec -it nginx-container sh

# Test communication
wget -qO- http://web-container

# Test DNS
getent hosts web-container

# Inspect network
docker network inspect app-network
```

---

# What I Learned

After completing this exercise, I understand:

* How to create a user-defined Docker network.
* How to connect multiple containers to the same network.
* How containers communicate using internal ports.
* Why container-to-container communication does not require `-p`.
* How Docker resolves container names.
* Why `localhost` means the current container.
* Why container names are better than hardcoded IP addresses.
* The difference between internal and published ports.
* Why containers need a shared network to communicate.
