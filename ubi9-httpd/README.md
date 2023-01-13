## hy-openshift-httpd 

### What is this?

This is a httpd image based on Red Hat's UBI image (version 9, ubi-minimal) and 
freely distributable repositories that can be easily used with OKD / Openshift 
environments with only the default `restriced` scc.

Maintained by University of Helsinki, no guarantees of any kind.

While you can serve static pages and do stuff by mounting your own configs with this 
image, it's more intended as a base for other stuff, namely SAML2 SP component.

### Why not just use rhel9/httpd as the base?

Licensing issues. We want to also have a httpd image as a base for other images 
we want to be able to distribute without access restrictions. This is not 
really borne out of needing to actually distribute any of our stuff far and wide, 
but rather to do away with configuring pull secret keys.

### License ?

Apache 2.0.

We do occasionally look into https://github.com/sclorg/httpd-container for guidance, 
which is licensed as Apache 2.0 as of this writing. 

### How to use?

You can mount the configurations, certificates and web root directory into 
the container at normal rhel / apache httpd places.

* `/var/www/html/ ...` for the static content files 
* `/etc/httpd/ ...` for configuration files
* `/etc/pki/ ...` for certificates and stuff
