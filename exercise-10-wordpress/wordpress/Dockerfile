FROM debian:bookworm

# Install PHP-FPM, required PHP extensions, MariaDB client and tools
RUN apt-get update && apt-get install -y \
    php-fpm \
    php-mysql \
    php-cli \
    php-curl \
    php-gd \
    php-mbstring \
    php-xml \
    php-zip \
    mariadb-client \
    curl \
    unzip \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# Working directory
WORKDIR /var/www/html

# Copy PHP-FPM configuration
# (Adjust the version directory if Debian installs another PHP version)
COPY tools/www.conf /etc/php/8.2/fpm/pool.d/www.conf
COPY tools/php.ini /etc/php/8.2/fpm/php.ini

# Copy startup script
COPY tools/run_wordpress.sh /usr/local/bin/run_wordpress.sh

RUN chmod +x /usr/local/bin/run_wordpress.sh

EXPOSE 9000

CMD ["/usr/local/bin/run_wordpress.sh"]