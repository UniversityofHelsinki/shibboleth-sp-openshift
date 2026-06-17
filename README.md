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

* `quay.io/tike/openshift-sp-shibd`, `:prod` and `:test`
* `quay.io/tike/openshift-sp-httpd`, `:prod` and `:test`

**NOTE:** All other tags are unsupported. If for some reason, something has been broken for you that our tests didn't catch, there should be some previous tags available. The `:YYYY-MM-DD` tags mean that "this image was `:prod` at the beginning of this date". These previous images do not get any updates and they are subject to be removed at later date without warning, so please use them only as short-term failsafes if you *really* need to get your service running *now*. They are likely rife with vulnerabilities and will not get patched.

Please inform us at grp-openshift-owner@helsinki.fi if the :prod or :test images are not working for you in University of Helsinki container platform environment. 
Include your project name and service url it is serving at.

For an example Openshift configuration, see [EXAMPLE_CONFIG.md](EXAMPLE_CONFIG.md).

## For someone keeping these images up to date: how to upgrade the images?

See [REPOUPDATES.md](REPOUPDATES.md).
