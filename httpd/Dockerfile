FROM registry.redhat.io/rhel8/httpd-24

USER 0
ADD shibboleth.repo /etc/yum.repos.d/
RUN yum install -y shibboleth

# Replace some config files with symlinks.
# Mount configMaps and secrets in /shib-config at Pod startup.
RUN ln -fs /shib-config/shibboleth2.xml /etc/shibboleth/ && \
    ln -fs /shib-config/attribute-map.xml /etc/shibboleth/attribute-map.xml

# 1) Delete default /secure path from shib.conf
# 2) Create empty index.html in document root
# 3) Include configuration files from ${HTTPD_CONFIGURATION_PATH}
RUN sed -i '/<Location \/secure>/,/<\/Location>/d' /etc/httpd/conf.d/shib.conf && \
    touch /var/www/html/index.html && \
    echo "IncludeOptional ${HTTPD_CONFIGURATION_PATH}/*.conf" > /etc/httpd/conf.d/include_custom.conf

# Mount your httpd configuration as a configMap in ${HTTPD_CONFIGURATION_PATH} (/opt/app-root/etc/httpd.d)

USER 1001

# Let the assemble script install the dependencies
# RUN /usr/libexec/s2i/assemble

# The run script uses standard ways to run the application
# CMD /usr/libexec/s2i/run
