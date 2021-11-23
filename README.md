# Shibboleth SP for OpenShift

This is an implementation of a Shibboleth SP reverse proxy for use in the Openshift clusters
at the University of Helsinki. It consists of two containers, one running the Shibboleth daemon
`shibd` and the other running the Apache web server `httpd`.

## How to pass user attributes?

If you need anything beyond verifying your user has a valid login,
Shibboleth may not be the optimal solution for you.
[See here for details before deciding to use these images for your project.](USING_ATTRIBUTES.md)

## Images

Ready to use container images are available to pull at:

* `quay.io/tike/shibboleth-sp-shibd`
* `quay.io/tike/shibboleth-sp-httpd`

For an example Openshift configuration, see [EXAMPLE_CONFIG.md](EXAMPLE_CONFIG.md).
