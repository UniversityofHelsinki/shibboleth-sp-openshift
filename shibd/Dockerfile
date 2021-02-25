FROM registry.access.redhat.com/ubi8/ubi

LABEL maintainer="ronja.koistinen@helsinki.fi"

# add Shibboleth RPM repository
COPY shibboleth.repo /etc/yum.repos.d/

# 1) Install Shibboleth
# 2) Change group ownership of all files contained in the Shibboleth package to
#    root. This is because Openshift runs the container process as a random UID
#    which is a member of the group root. By doing this chgrp we make sure the process
#    can access all the files it needs.
# 3) Give the root group write permissions to directories which shibd needs to write in
RUN yum install -y shibboleth && \
    rpm -ql shibboleth | xargs chgrp root && \
	chmod g+w /var/log/shibboleth /etc/shibboleth

COPY sign-login.helsinki.fi.crt /etc/shibboleth/

# This is just for best practices. Ignored by Openshift.
USER shibd

EXPOSE 1600

CMD ln -sf -t /etc/shibboleth/ /shib-config/*; /usr/sbin/shibd -F
