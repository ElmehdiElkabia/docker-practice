FROM debian:latest

RUN apt-get update && apt install -y mariadb-server mariadb-client

COPY ./50-server.cnf /etc/mysql/mariadb.conf.d/.

COPY ./script.sh /usr/local/bin/script.sh

RUN chmod +x /usr/local/bin/script.sh && \
    mkdir -p /run/mysqld && \
    chown -R mysql:mysql /run/mysqld /var/lib/mysql

EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/script.sh"]