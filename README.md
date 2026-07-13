# Docker Practice

This repository is a step-by-step Docker learning path. It starts with building and running a single container, then moves into image layering, static web serving, networking, HTTPS, Docker Compose, MariaDB, WordPress, and a small multi-service stack.

The exercises are intentionally ordered so each new folder adds one more Docker concept on top of the previous one. By the end of the repo, you should understand how to build images, run containers, connect services, persist data, and expose a full stack through NGINX.

## What You Need

* Docker
* Docker Compose
* A shell that can run `docker` commands

## How To Use This Repo

Each exercise lives in its own folder and has its own README. The usual workflow is:

1. Open the exercise folder.
2. Read the local README.
3. Build and run from that folder.

Most later exercises use:

```bash
docker compose up --build
```

The earlier exercises focus on `docker build`, `docker run`, and `docker network`.

If you are learning in order, the best way to use the repo is to finish one exercise before moving to the next. Many later folders reuse ideas from earlier ones, so the progression matters.

## What This Repo Teaches

This project covers the most common building blocks of Docker-based development:

* how an image is assembled from a Dockerfile
* how containers are started from images
* how layer cache speeds up rebuilds
* how NGINX serves static content and acts as a reverse proxy
* how HTTPS works with self-signed certificates
* how Docker networks let containers discover each other by name
* how Compose manages multi-service applications
* how volumes keep database and application data across restarts

The later exercises combine these pieces into realistic application stacks.

## Learning Path

### 1. Image Basics

Exercises 01 to 03 focus on how images are built and how containers are created from them.

* [exercise-01-basic-image](exercise-01-basic-image) introduces the Dockerfile, image creation, and a container running a simple command. The important idea here is that a container is just a running instance of an image, not a separate application format.
* [exercise-02-cpp-app](exercise-02-cpp-app) builds a C++ application inside an image and shows how Docker can compile code during build time. This is where you start seeing Docker as a reproducible build environment, not just a runtime tool.
* [exercise-03-layers-cache](exercise-03-layers-cache) explains image layers, build cache, and why Dockerfile instruction order matters. This exercise is especially useful because it shows why copying dependency files before source code can make rebuilds much faster.

### 2. NGINX and Web Serving

Exercises 04 and 05 move from raw images to serving web content.

* [exercise-04-nginx](exercise-04-nginx) shows how to run NGINX in a container and serve static files over HTTP. This introduces custom NGINX configuration and port mapping from the host into the container.
* [exercise-05-nginx-https](exercise-05-nginx-https) adds HTTPS, a self-signed certificate, and TLS configuration on port 443. Here you start working with the difference between plain HTTP traffic and encrypted HTTPS traffic.

### 3. Networking and Reverse Proxying

Exercises 06 and 07 introduce communication between containers.

* [exercise-06-docker-network](exercise-06-docker-network) demonstrates a user-defined bridge network and container-to-container DNS. The key lesson is that services on the same network can reach each other by name instead of by hardcoded IP address.
* [exercise-07-reverse-proxy](exercise-07-reverse-proxy) turns NGINX into a reverse proxy that terminates TLS and forwards requests to an internal app container. This is the point where you separate the public entry point from the internal application service.

### 4. Docker Compose

Exercises 08 to 11 build larger systems with multiple services.

* [exercise-08-compose](exercise-08-compose) shows how Compose wires an app service and an NGINX reverse proxy together on one network. This introduces service definitions, automatic network creation, and the `depends_on` relationship.
* [exercise-09-mariadb](exercise-09-mariadb) creates a MariaDB container that initializes itself and stores data in a named volume. The database is configured through environment variables so the container can start with the right schema and credentials.
* [exercise-10-wordpress](exercise-10-wordpress) connects WordPress to MariaDB and exposes the site on host port 8080. This is the first exercise where a web application depends on a separate database container.
* [exercise-11-mini-inception](exercise-11-mini-inception) combines MariaDB, WordPress, and NGINX into a small full-stack deployment. It adds a PHP-FPM WordPress service, an HTTPS NGINX entry point, and a shared volume for the site files.

## Full Exercise Overview

### Exercise 01 — Basic Docker Image & Container

Build your first image from a Dockerfile, inspect it, and run a container from it. The focus is the basic lifecycle:

```text
Dockerfile -> Image -> Container
```

This exercise is about understanding that the Dockerfile describes a recipe, the image is the built artifact, and the container is the running result. Once that distinction is clear, the rest of the repo becomes much easier to follow.

### Exercise 02 — C++ Application Inside Docker

Use Docker to compile a C++ application during image build. This exercise introduces build context, `Makefile`-driven builds, and how a container behaves when the main process exits.

The important lesson here is that Docker can be used as a consistent build environment. The image contains the compiler, the build tools, and the application output, so the same build process works the same way on any machine with Docker installed.

### Exercise 03 — Docker Layers & Build Cache

Learn why copying dependency files before source code helps Docker reuse cached layers. This exercise is about build performance and reproducible image construction.

If you only change source files, Docker can reuse the earlier layers that installed tools and compiled dependencies. That makes iterative development faster and shows why Dockerfile order has a real effect on build time.

### Exercise 04 — NGINX with Docker

Run NGINX as a containerized web server, replace the default configuration, and serve a custom static site.

This exercise teaches the basic structure of an NGINX container: base image, custom config, copied static files, and a published port. It is the first step toward using containers as web servers instead of only as application runners.

### Exercise 05 — NGINX with HTTPS/TLS

Add TLS to the NGINX setup using a self-signed certificate. This exercise shows how HTTPS works in a container and why certificate trust matters.

You learn how the certificate and private key are mounted into the image, how NGINX is configured to listen on 443, and why browsers warn about self-signed certificates even when the server is correctly configured.

### Exercise 06 — Two Containers on One Docker Network

Create a custom bridge network and let one container reach another by service name instead of IP address.

This is where Docker networking becomes practical: container names become DNS entries, so one service can talk to another without hardcoding addresses that may change when containers are recreated.

### Exercise 07 — Reverse Proxy with NGINX

Use NGINX as a reverse proxy in front of a simple app container. NGINX handles HTTPS on the outside and forwards requests to HTTP on the inside.

This pattern is important because it separates concerns cleanly. The proxy handles encryption and public access, while the app container stays simple and only serves the application itself.

### Exercise 08 — Docker Compose for Reverse Proxy

Replace manual container management with Compose. This exercise shows service definitions, networks, and `depends_on` in a practical two-container setup.

Compose reduces the amount of manual container orchestration you need to do. Instead of starting containers one by one, you define the stack in a single file and let Compose create the network and wire the services together.

### Exercise 09 — MariaDB with Docker Compose

Build a MariaDB service that configures itself from environment variables and persists its database files with a named volume.

The main point here is persistence. A database container without a volume loses its data when it is removed, so this exercise shows how to keep the data directory outside the container lifecycle.

### Exercise 10 — WordPress with MariaDB

Connect WordPress to MariaDB using Compose networking. This exercise introduces app/database separation and volume-backed persistence for the WordPress files.

You now have a real application stack where the frontend and the database are separate services. WordPress gets its database connection details from environment variables, which mirrors how many production-style container deployments are configured.

### Exercise 11 — Mini Inception

Combine WordPress, MariaDB, and NGINX into one stack. NGINX serves HTTPS, WordPress runs as PHP-FPM, and MariaDB stores the data.

This is the most complete exercise in the repository. It combines TLS, reverse proxying, PHP-FPM, shared volumes, database initialization, and Compose networking into a single deployment that behaves like a small real-world web application.

## Common Concepts Used Across the Repo

* `Dockerfile` for building images
* `docker build` for turning source into images
* `docker run` for creating containers from images
* `docker network` for container communication
* `docker compose` for multi-service applications
* named volumes for persistent data
* NGINX for static serving and reverse proxying
* MariaDB for relational storage
* self-signed certificates for local HTTPS testing

## The Big Picture

The repo moves through three stages:

1. Build and run a single container.
2. Connect containers together with networks and proxying.
3. Manage a full application stack with Compose, volumes, and environment variables.

If you understand those three stages, you understand the main goal of the whole repository.

## Notes

* Some exercises use self-signed certificates, so browser warnings are expected.
* Database exercises depend on environment variables and volumes to initialize and persist data.
* Later exercises rely on service names and Docker networks, so container names are important.
* If you want to practice in order, do not skip the earlier exercises, because the later ones assume the same concepts.


