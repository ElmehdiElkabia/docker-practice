FROM nginx:alpine

RUN apk add --no-cache bash && apk add --no-cache openssl

RUN rm /etc/nginx/conf.d/default.conf

COPY nginx.conf /etc/nginx/conf.d/default.conf

COPY script.sh /usr/bin/script.sh

RUN chmod +x /usr/bin/script.sh

EXPOSE 443

CMD ["/usr/bin/script.sh"]