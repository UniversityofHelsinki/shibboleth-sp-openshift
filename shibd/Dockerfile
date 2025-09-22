FROM registry.access.redhat.com/ubi9/ubi-minimal

LABEL maintainer="grp-openshift-admin@helsinki.fi"
LABEL ImageName=openshift-sp-shibd

# add Shibboleth RPM repository
COPY shibboleth.repo /etc/yum.repos.d/

# 1) Install Shibboleth (and nmap-ncat for liveness-probing)
# 2) Add the shibd user to the group 'root'. This enables running this container outside Openshift
#    or a similar environment which forces the group of the PID 1 process to 'root'.
# 3) Change group ownership of all files contained in the Shibboleth package to
#    root. This is because Openshift runs the container process as a random UID
#    which is a member of the group root. By doing this chgrp we make sure the process
#    can access all the files it needs.
# 4) Give the root group write permissions to directories which shibd needs to write in
# 5) Delete some generated and not-to-be-used files in order to appease image scanners
#    (and maybe force-prevent some misconfiguration problems too...)
RUN microdnf \
            --disableplugin=subscription-manager --disablerepo="*" \
            --enablerepo="ubi-9-appstream-rpms" --enablerepo="ubi-9-baseos-rpms"  --enablerepo="shibboleth" \
        install -y shibboleth nmap-ncat findutils && \
    microdnf clean all && \
    usermod -a -G root shibd && \
    rpm -ql shibboleth | xargs chgrp root && \
    chmod g+w /var/log/shibboleth /etc/shibboleth && \
    rm \
        /etc/shibboleth/sp-signing-cert.pem \
        /etc/shibboleth/sp-signing-key.pem \
        /etc/shibboleth/sp-encrypt-cert.pem \
        /etc/shibboleth/sp-encrypt-key.pem

COPY sign-login.helsinki.fi.crt /etc/shibboleth/
COPY modified_templates/*.html /etc/shibboleth/
COPY base_shibboleth_configs/* /etc/shibboleth/
COPY --chown=shibd:root start.sh /usr/local/bin/start.sh

RUN chmod g+x /usr/local/bin/start.sh

RUN microdnf \
            --disableplugin=subscription-manager --disablerepo="*" \
            --enablerepo="ubi-9-appstream-rpms" --enablerepo="ubi-9-baseos-rpms"  --enablerepo="shibboleth" \
        upgrade -y && \
    microdnf clean all

# This is just for best practices. Ignored by Openshift.
USER shibd

EXPOSE 1600

CMD /usr/local/bin/start.sh
