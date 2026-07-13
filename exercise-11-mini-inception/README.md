# Exercise 11 — Mini Inception

## Objective

The goal of this exercise is to build a small WordPress stack with three containers:

* MariaDB for the database
* WordPress for the PHP application
* NGINX as the HTTPS reverse proxy

This exercise combines the ideas from the previous exercises into one stack.

---

## Project Structure

```text
exercise-11-mini-inception/
├── compose.yml
├── README.md
├── mariadb/
│   ├── 50-server.cnf
│   ├── Dockerfile
│   └── script.sh
├── nginx/
│   ├── Dockerfile
│   ├── nginx.conf
│   └── script.sh
└── wordpress/
		└── Dockerfile
```

---

## 1. MariaDB Service

The MariaDB container installs the database server, initializes the data directory, and creates the WordPress database and user.

### Dockerfile

```dockerfile
FROM debian:latest

RUN apt-get update && \
		apt-get install -y mariadb-server && \
		rm -rf /var/lib/mysql/* 

COPY ./50-server.cnf /etc/mysql/mariadb.conf.d/.

COPY ./script.sh /usr/local/bin/script.sh

RUN chmod +x /usr/local/bin/script.sh

EXPOSE 3306

CMD ["/usr/local/bin/script.sh"]
```

The startup script initializes MariaDB only when the data directory is empty.

---

## 2. WordPress Service

The WordPress container runs PHP-FPM.

### Dockerfile

```dockerfile
FROM wordpress:6.6-fpm
```

NGINX forwards PHP requests to this service on port 9000.

---

## 3. NGINX Service

The NGINX container serves HTTPS, generates a self-signed certificate, and forwards PHP requests to WordPress.

### Dockerfile

```dockerfile
FROM nginx:alpine

RUN apk add --no-cache bash && apk add --no-cache openssl

RUN rm /etc/nginx/conf.d/default.conf

COPY nginx.conf /etc/nginx/conf.d/default.conf

COPY script.sh /usr/bin/script.sh

RUN chmod +x /usr/bin/script.sh

EXPOSE 443

CMD ["/usr/bin/script.sh"]
```

### NGINX Configuration

```nginx
server {
		listen 443 ssl;
		server_name localhost;

		ssl_certificate /etc/ssl/certs/server.crt;
		ssl_certificate_key /etc/ssl/certs/server.key;

		ssl_protocols TLSv1.2 TLSv1.3;

		root /var/www/html;
		index index.php index.html index.htm;

		location / {
				try_files $uri $uri/ /index.php?$args;
		}

		location ~ \.php$ {
				fastcgi_pass wordpress:9000;
				fastcgi_index index.php;
				fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
				include fastcgi_params;
		}
}
```

### NGINX Startup Script

The [nginx/script.sh](nginx/script.sh) script generates a self-signed certificate in `/etc/ssl/certs/` and then starts NGINX.

---

## 4. Docker Compose

```yaml
services:
	mariadb:
		build: ./mariadb
		restart: always
		environment:
			MYSQL_ROOT_PASSWORD: rootpassword
			MYSQL_DATABASE: wordpress
			MYSQL_USER: wordpressuser
			MYSQL_PASSWORD: wordpresspassword
		volumes:
			- mariadb_data:/var/lib/mysql
		networks:
			- mini-inception

	wordpress:
		build: ./wordpress
		restart: always
		environment:
			WORDPRESS_DB_HOST: mariadb:3306
			WORDPRESS_DB_NAME: wordpress
			WORDPRESS_DB_USER: wordpressuser
			WORDPRESS_DB_PASSWORD: wordpresspassword
		depends_on:
			- mariadb
		volumes:
			- wordpress_data:/var/www/html
		networks:
			- mini-inception

	nginx:
		build: ./nginx
		restart: always
		ports:
			- "443:443"
		depends_on:
			- wordpress
		networks:
			- mini-inception
		volumes:
			- wordpress_data:/var/www/html

volumes:
	mariadb_data:
	wordpress_data:

networks:
	mini-inception:
		driver: bridge
```

The same WordPress volume is mounted into NGINX so the web server can serve the site files.

---

## 5. Request Flow

```text
Browser
	│
	│ https://localhost
	▼
NGINX
	│
	│ FastCGI to wordpress:9000
	▼
WordPress (PHP-FPM)
	│
	│ SQL over Docker network
	▼
MariaDB
```

NGINX terminates TLS, WordPress executes PHP, and MariaDB stores the data.

---

## 6. Build and Run

Start the full stack:

```bash
docker compose up --build
```

Open the site in a browser:

```text
https://localhost
```

Because the certificate is self-signed, the browser will show a warning unless the certificate is trusted manually.

