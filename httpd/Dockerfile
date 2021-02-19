FROM registry.redhat.io/rhel8/httpd-24

USER 0
ADD shibboleth.repo /etc/yum.repos.d/
RUN yum install -y shibboleth

# Replace some config files with symlinks.
# Mount configMaps and secrets in /shib-config at Pod startup.
RUN ln -fs /shib-config/shibboleth2.xml /etc/shibboleth/ && \
    ln -fs /shib-config/attribute-map.xml /etc/shibboleth/attribute-map.xml

# Mount your httpd configuration as a configMap in ${HTTPD_CONFIGURATION_PATH}

USER 1001

# Let the assemble script install the dependencies
# RUN /usr/libexec/s2i/assemble

# The run script uses standard ways to run the application
# CMD /usr/libexec/s2i/run
