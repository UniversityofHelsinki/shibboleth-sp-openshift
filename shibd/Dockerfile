FROM registry.access.redhat.com/ubi8/ubi

LABEL maintainer="ronja.koistinen@helsinki.fi"

# add Shibboleth RPM repository
COPY shibboleth.repo /etc/yum.repos.d/

# 1) Install Shibboleth
# 2) Change group ownership of all files contained in the Shibboleth package to
#    root. This is because Openshift runs the container process as a random UID
#    which is a member of the group root. By doing this chgrp we make sure the process
#    can access all the files it needs.
RUN yum install -y shibboleth && \
    rpm -ql shibboleth | xargs chgrp root && \
	chmod g+w /var/log/shibboleth

# Replace some config files with symlinks.
# Mount configMaps and secrets in /shib-config at Pod startup.
RUN ln -fs /shib-config/shibboleth2.xml /etc/shibboleth/shibboleth2.xml && \
    ln -fs /shib-config/attribute-map.xml /etc/attribute-map.xml
COPY sign-login.helsinki.fi.crt /etc/shibboleth/

# This is just for best practices. Ignored by Openshift.
USER shibd

EXPOSE 1600

CMD /usr/sbin/shibd -F
