FROM nginx:1.27-alpine

LABEL maintainer="Markus Stuefer"
LABEL app="homelabwebgui"

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY . /usr/share/nginx/html/

RUN rm -f /usr/share/nginx/html/nginx.conf \
    && find /usr/share/nginx/html -type f -name "*.html" -exec chmod 644 {} \; \
    && find /usr/share/nginx/html -type f -name "*.css" -exec chmod 644 {} \; \
    && find /usr/share/nginx/html -type f -name "*.js" -exec chmod 644 {} \;

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD wget -qO- http://127.0.0.1/health || exit 1