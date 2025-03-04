FROM --platform=linux/arm64 nginx:stable-alpine
LABEL maintainer="Paschoal Diniz <aiservers.brasil@gmail.com>"

COPY website /website
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80
