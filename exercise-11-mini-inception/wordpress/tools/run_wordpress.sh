#!/bin/bash

set -e

echo "Waiting for MariaDB..."

# TODO:
# Wait until MariaDB accepts connections
MAX_RETRIES=30
COUNT=0
while [ $COUNT -lt $MAX_RETRIES ]; do
    if mariadb-admin ping \
        --host="mariadb" \
        --user="$WORDPRESS_DB_USER" \
        --password="$WORDPRESS_DB_PASSWORD" \
        --silent 2>/dev/null; then
        echo "✅ MariaDB ready"
        break
    fi
    COUNT=$((COUNT + 1))
    sleep 2
done
# Hint: use mariadb-admin ping or mysqladmin ping


cd /var/www/html

# Download WordPress only if it doesn't exist
if [ ! -f index.php ]; then
    echo "Downloading WordPress..."
    # TODO:
    # wp core download --allow-root
    wp core download --allow-root --locale=en_US
fi

# Create wp-config.php only if it doesn't exist
if [ ! -f wp-config.php ]; then
    echo "Creating wp-config.php..."
    # TODO:
    # wp config create ...
    if [ ! -f wp-config.php ]; then
        wp config create --allow-root \
        --dbname="$WORDPRESS_DB_NAME" \
        --dbuser="$WORDPRESS_DB_USER" \
        --dbpass="$WORDPRESS_DB_PASSWORD" \
        --dbhost="$WORDPRESS_DB_HOST" \
        --locale=en_US

    wp config set --allow-root WP_HOME "https://localhost"
    wp config set --allow-root WP_SITEURL "https://localhost"
    fi
    echo "Conplating wp-config.php..."
fi

# Install WordPress only if it is not installed
if ! wp core is-installed --allow-root; then
    echo "Installing WordPress..."

    # TODO:
    # wp core install ...
    if ! wp core is-installed --allow-root; then
        wp core install --allow-root \
            --url="http://localhost:8080" \
            --title="My WordPress Site" \
            --admin_user="$WP_ADMIN_USER" \
            --admin_password="$WP_ADMIN_PASSWORD" \
            --admin_email="$WP_ADMIN_EMAIL"
    fi


    #WP_URL: https://eelkabia.42.fr for inception 
    #     wp core install --allow-root \
    # --url="$WP_URL" \
    # --title="$WP_TITLE" \
    # --admin_user="$WP_ADMIN_USER" \
    # --admin_password="$WP_ADMIN_PASSWORD" \
    # --admin_email="$WP_ADMIN_EMAIL"

    echo "Creating user..."

    # TODO:
    # wp user create ...
    EDITOR_PASSWORD="Editor_$(date +%s | tail -c 6)"
    wp user create --allow-root \
        editor \
        editor@admin.com \
        --role=editor \
        --user_pass="$EDITOR_PASSWORD" \
        --allow-root
    echo "Editor user created with password: $EDITOR_PASSWORD"

fi

echo "Starting PHP-FPM..."

exec php-fpm8.2 -F