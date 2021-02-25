# Shibboleth SP for OpenShift

This is an implementation of a Shibboleth SP reverse proxy for use in the Openshift clusters
at the University of Helsinki. It consists of two containers, one running the Shibboleth daemon
`shibd` and the other running the Apache web server `httpd`.

Ready to use container images are available to pull at:

* `quay.io/tike/shibboleth-sp-shibd`
* `quay.io/tike/shibboleth-sp-httpd`

For an example Openshift configuration, see [EXAMPLE_CONFIG.md](EXAMPLE_CONFIG.md).

## TODO

* Make the shibd container write logs in stdout, rather than `/var/log/shibboleth/shibd.log`.
