# A shibd container image intended for OpenShift

Run this container in a single Pod together with the httpd container.
Shibd listens on localhost on port 1600.
Containers sharing a Pod share a common localhost.

## Configuration

### Ansible variables

* `application_host` -- FQDN where your application is served
* `hy_login_server` -- login.helsinki.fi or login-test.helsinki.fi
* `shib_attributes` -- user attributes your SP requests from the IdP
  * string variable containing XML `<Attribute/>`

Ansible inserts these values into `shibboleth2.xml` and `attribute-map.xml` through templates (see `/ansible/templates/shibd`).
The resulting files are mounted under `/shib-config/` in the application container by way of Kubernetes `ConfigMap` objects.

### Secrets

The certificate and key files specific to your application.
The certificate must be registered with the [SP Registry](https://sp-registry.it.helsinki.fi/).

Mount the secrets in this container in these paths:

* `/shib-config/shib-cert.pem`
* `/shib-config/shib-key.pem`
