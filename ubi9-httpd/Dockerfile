FROM registry.access.redhat.com/ubi9/ubi-minimal

LABEL maintainer="atk-verkkopalvelut@helsinki.fi"
LABEL ImageName=ubi9-httpd

RUN microdnf \
            --disableplugin=subscription-manager --disablerepo="*" \
            --enablerepo="ubi-9-appstream-rpms" --enablerepo="ubi-9-baseos-rpms" \
        install -y \
        gettext hostname nss_wrapper-libs bind-utils httpd mod_ssl \
        mod_ldap mod_session mod_security mod_auth_mellon sscg \
    && \
    microdnf \
            --disableplugin=subscription-manager --disablerepo="*" \
            --enablerepo="ubi-9-appstream-rpms" --enablerepo="ubi-9-baseos-rpms" \
        upgrade -y \
    && \
    microdnf \
        clean all

# Change the user and group ID of the 'apache' user to a non-privileged ID
RUN usermod -u 1001 apache && \
    groupmod -g 1001 apache && \
    groupmod -o -g 0 apache

ADD files/httpd.conf /etc/httpd/conf/httpd.conf
ADD files/ssl.conf /etc/httpd/conf.d/ssl.conf
ADD files/welcome.conf /etc/httpd/conf.d/welcome.conf
ADD files/index.html /var/www/html/index.html

# Change the permissions of the '/var/run/httpd' directory so that 
# the 'apache' user can write to it
RUN chgrp -R 0 /var/run/httpd && \
    chmod -R g+rwX /var/run/httpd && \
    touch /var/log/httpd/modsec_debug.log && \
    chgrp -R 0 /var/log/httpd && \
    chmod -R g+rwX /var/log/httpd

RUN /usr/libexec/httpd-ssl-gencerts

RUN chgrp 0 /etc/pki/tls/private/localhost.key && \
    chmod og+x /etc/pki/tls/private && \
    chmod og+r /etc/pki/tls/private/localhost.key

EXPOSE 8080
EXPOSE 8443

USER 1001

CMD ["httpd", "-D", "FOREGROUND"]
