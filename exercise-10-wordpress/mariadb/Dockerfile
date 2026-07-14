FROM debian:latest

RUN apt-get update && \
    apt-get install -y mariadb-server && \
    rm -rf /var/lib/mysql/* 

COPY ./50-server.cnf /etc/mysql/mariadb.conf.d/.

COPY ./script.sh /usr/local/bin/script.sh

RUN chmod +x /usr/local/bin/script.sh

EXPOSE 3306

CMD ["/usr/local/bin/script.sh"]