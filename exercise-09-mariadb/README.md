# Exercise 09 — MariaDB with Docker Compose

## Objective

The goal of this exercise is to build a MariaDB container that initializes itself on startup and persists its data with a Docker volume.

In this setup:

* MariaDB runs inside a custom container
* the database is initialized from an entrypoint script
* data is stored in a named volume
* the container exposes port 3306

---

## Project Structure

```text
exercise-09-mariadb/
├── compose.yaml
├── Dockerfile
├── README.md
└── init/
		├── 50-server.cnf
		└── init_db.sh
```

---

## 1. The MariaDB Image

The Dockerfile installs MariaDB Server and uses a custom initialization script.

### Dockerfile

```dockerfile
FROM debian:latest

RUN apt-get update && apt-get install -y mariadb-server && rm -rf /var/lib/apt/lists/*

COPY init/50-server.cnf /etc/mysql/mariadb.conf.d/.

COPY init/init_db.sh /usr/local/bin/init_db.sh

RUN chmod +x /usr/local/bin/init_db.sh && \
		mkdir -p /run/mysqld && \
		chown -R mysql:mysql /run/mysqld /var/lib/mysql

EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/init_db.sh"]
```

---

## 2. MariaDB Configuration

The custom [init/50-server.cnf](init/50-server.cnf) file adjusts MariaDB server settings.

The important part for container use is:

```text
bind-address = 0.0.0.0
```

This allows MariaDB to accept connections from outside the container.

---

## 3. Initialization Script

The [init/init_db.sh](init/init_db.sh) script bootstraps the database the first time the container starts.

It does three main things:

* creates the MariaDB system tables if needed
* sets the root password
* creates a database and user for the application

The script uses `mysqld --bootstrap` to create the initial database state, then starts MariaDB normally.

---

## 4. Docker Compose

```yaml
services:
	mariadb:
		build: .
		container_name: mariadb
		volumes:
			- mariadb_data:/var/lib/mysql
		ports:
			- "3306:3306"
		environment:
			MYSQL_ROOT_PASSWORD: qifrey
			MYSQL_DATABASE: qifrey_database
			MYSQL_USER: qifrey
			MYSQL_PASSWORD: qifrey
		restart: always

volumes:
	mariadb_data:
```

The named volume keeps the database files even if the container is removed.

---

## 5. Build and Run

Start the service:

```bash
docker compose up --build
```

The MariaDB server will be available on:

```text
localhost:3306
```

If you restart the container, the volume keeps the existing database state.

