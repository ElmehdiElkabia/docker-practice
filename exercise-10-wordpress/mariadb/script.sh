#!/bin/bash

set -e

# Initialize the database only if it hasn't been initialized yet
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB data directory..."

    mariadb-install-db --user=mysql --datadir=/var/lib/mysql

    echo "Starting temporary MariaDB server..."

    mariadbd-safe --user=mysql --datadir=/var/lib/mysql &

    echo "Waiting for MariaDB to start..."

    until mysqladmin ping --silent; do
        sleep 1
    done

    echo "Setting root password and creating database/user..."

    mysql -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;

CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';

GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';

FLUSH PRIVILEGES;
EOF

    echo "Stopping temporary MariaDB server..."

    mysqladmin -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown


    echo "MariaDB initialization completed."
else
    echo "MariaDB data directory already initialized."
fi

echo "Starting MariaDB..."

exec /usr/sbin/mariadbd \
    --user=mysql \
    --datadir=/var/lib/mysql