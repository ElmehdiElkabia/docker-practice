FROM nginx:alpine

RUN rm /etc/nginx/conf.d/default.conf

COPY nginx.conf /etc/nginx/conf.d/default.conf

COPY certs/ /etc/ssl/certs/

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]