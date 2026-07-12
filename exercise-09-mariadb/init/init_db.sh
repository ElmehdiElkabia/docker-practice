#!/bin/bash

# Start MariaDB temporarily
# we use the mysqld with option --bootstrap 
# This option is used by the mysql_install_db script to create the MySQL privilege tables without having to start a full MySQL server.
# This mysql_install_db using the mariadb-install-db for initializes the MariaDB data directory and creates the system tables in the mysql database.
mysqld --user=mysql --bootstrap << EOF

USE mysql;
FLUSH PRIVILEGES;

-- Set root password
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

-- Create WordPress database
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};

-- Create WordPress user
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';

-- Grant permissions
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;

EOF

#get the pid 1 
exec mysqld --user=mysql