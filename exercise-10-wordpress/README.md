# Exercise 10 — WordPress with MariaDB

## Objective

The goal of this exercise is to connect a WordPress container to a MariaDB container with Docker Compose.

In this setup:

* MariaDB stores the WordPress database
* WordPress connects to MariaDB over the Compose network
* WordPress is exposed on host port 8080
* MariaDB is exposed on host port 3306

---

## Project Structure

```text
exercise-10-wordpress/
├── compose.yml
├── README.md
├── mariadb/
│   ├── 50-server.cnf
│   ├── Dockerfile
│   └── script.sh
└── wordpress/
		└── Dockerfile
```

---

## 1. MariaDB Service

The MariaDB container installs the database server, configures it, and initializes the WordPress database.

### Dockerfile

```dockerfile
FROM debian:latest

RUN apt-get update && \
		apt install -y mariadb-server mariadb-client

COPY ./50-server.cnf /etc/mysql/mariadb.conf.d/.

COPY ./script.sh /usr/local/bin/script.sh

RUN chmod +x /usr/local/bin/script.sh && \
		mkdir -p /run/mysqld && \
		chown -R mysql:mysql /run/mysqld /var/lib/mysql

EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/script.sh"]
```

The initialization script creates the database and user on first startup.

---

## 2. WordPress Service

The WordPress image is built from the official image.

### Dockerfile

```dockerfile
FROM wordpress:latest
```

The WordPress container uses the environment variables from Compose to connect to MariaDB.

---

## 3. Docker Compose

```yaml
services:
	mariadb:
		build: ./mariadb
		ports:
			- "3306:3306"
		volumes:
			- mariadb_data:/var/lib/mysql
		environment:
			MYSQL_ROOT_PASSWORD: rootpassword
			MYSQL_DATABASE: wordpress
			MYSQL_USER: wpuser
			MYSQL_PASSWORD: password123
		networks:
			- wordpress-network

	wordpress:
		build: ./wordpress
		ports:
			- "8080:80"
		volumes:
			- wordpress_data:/var/www/html
		networks:
			- wordpress-network
		environment:
			WORDPRESS_DB_HOST: mariadb:3306
			WORDPRESS_DB_USER: wpuser
			WORDPRESS_DB_PASSWORD: password123
			WORDPRESS_DB_NAME: wordpress

volumes:
	mariadb_data:
	wordpress_data:

networks:
	wordpress-network:
		driver: bridge
```

The WordPress service reaches the database by using the service name `mariadb`.

---

## 4. Request Flow

```text
Browser
	│
	│ http://localhost:8080
	▼
WordPress container
	│
	│ SQL over Docker network
	▼
MariaDB container
```

WordPress serves the site, and MariaDB stores the backend data.

---

## 5. Build and Run

Start the stack:

```bash
docker compose up --build
```

Open WordPress in the browser:

```text
http://localhost:8080
```

---

## 6. What This Exercise Teaches

This exercise shows how to:

* connect two services with Docker Compose
* pass database settings through environment variables
* keep database data in volumes
* expose only the services that need host access

