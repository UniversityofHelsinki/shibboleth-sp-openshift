FROM quay.io/tike/ubi9-httpd:test

LABEL maintainer="grp-openshift-admin@helsinki.fi"
LABEL ImageName=openshift-sp-httpd

USER 0

ADD shibboleth.repo /etc/yum.repos.d/

# 1) Install Shibboleth
# 2) Change the group of /etc/shibboleth to root
# 3) Give the group write permissions to /etc/shibboleth
# 4) Delete some generated and not-to-be-used files in order to appease image
#  scanners (and maybe force-prevent some misconfiguration problems too...)
RUN microdnf \
        clean all && \
    microdnf \
            --disableplugin=subscription-manager --disablerepo="*" \
            --enablerepo="ubi-9-appstream-rpms" --enablerepo="ubi-9-baseos-rpms" --enablerepo="shibboleth" \
        install -y \
        shibboleth && \
    chgrp root /etc/shibboleth && \
    chmod g+w /etc/shibboleth && \
    rm -f \
        /etc/shibboleth/sp-signing-cert.pem \
        /etc/shibboleth/sp-signing-key.pem \
        /etc/shibboleth/sp-encrypt-cert.pem \
        /etc/shibboleth/sp-encrypt-key.pem

# Finally, make sure everything is up-to-date
RUN microdnf \
            --disableplugin=subscription-manager --disablerepo="*" \
            --enablerepo="ubi-9-appstream-rpms" --enablerepo="ubi-9-baseos-rpms" --enablerepo="shibboleth" \
        upgrade -y && \
    microdnf \
        clean all

# 1) Delete default /secure path from shib.conf
# 2) Create empty index.html in document root
# 3) Include configuration files from /opt/app-root/etc/httpd.d
#     -- this path is a bit vestigial but it's been given in example config 
#        and has now become essentially part of our usage contract 
#        so changing it would be hard...
RUN sed -i '/<Location \/secure>/,/<\/Location>/d' /etc/httpd/conf.d/shib.conf && \
    truncate -s 0 /var/www/html/index.html && \
    echo "IncludeOptional /opt/app-root/etc/httpd.d/*.conf" > \
         /etc/httpd/conf.d/include_custom.conf

ADD cmd.sh /opt/src/cmd.sh

RUN chgrp -R 0 /opt/src && \
    chmod -R g=u /opt/src && \
    chmod +x /opt/src/cmd.sh

USER 1001

COPY modified_templates/*.html /etc/shibboleth/
COPY files/protocols.xml /etc/shibboleth/protocols.xml
COPY files/set_forwarded_remote_ip.conf /etc/httpd/conf.d/set_forwarded_remote_ip.conf

ENTRYPOINT ["/opt/src/cmd.sh"]
