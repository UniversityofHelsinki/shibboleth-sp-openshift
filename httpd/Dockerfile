FROM registry.redhat.io/rhel8/httpd-24

LABEL maintainer="atk-verkkopalvelut@helsinki.fi"
LABEL ImageName=openshift-sp-httpd

USER 0
ADD shibboleth.repo /etc/yum.repos.d/
# 1) Install Shibboleth
# 2) Change the group of /etc/shibboleth to root
# 3) Give the group write permissions to /etc/shibboleth
RUN yum install -y shibboleth && \
    chgrp root /etc/shibboleth && \
    chmod g+w /etc/shibboleth

# 1) Delete default /secure path from shib.conf
# 2) Create empty index.html in document root
# 3) Include configuration files from ${HTTPD_CONFIGURATION_PATH}
RUN sed -i '/<Location \/secure>/,/<\/Location>/d' /etc/httpd/conf.d/shib.conf && \
    touch /var/www/html/index.html && \
    echo "IncludeOptional ${HTTPD_CONFIGURATION_PATH}/*.conf" > /etc/httpd/conf.d/include_custom.conf

# Mount your httpd configuration as a configMap in ${HTTPD_CONFIGURATION_PATH} (/opt/app-root/etc/httpd.d)

RUN dnf update -y

USER 1001

HEALTHCHECK --interval=1m --timeout=30s \
    CMD curl -f http://localhost:8080/Shibboleth.sso/Status || exit 1

COPY modified_templates/*.html /etc/shibboleth/
CMD ln -sf -t /etc/shibboleth/ /shib-config/*; /usr/sbin/apachectl -t -D DUMP_INCLUDES; run-httpd
