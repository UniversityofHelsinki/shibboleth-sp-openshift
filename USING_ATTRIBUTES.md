# Using Attributes In Your Application

1. In the [SP registry](https://sp-registry.it.helsinki.fi/),
select which attributes your application needs from the IdP.

2. Select one of the myriad ways your application can
receive attributes from the IdP.
(One very valid option is to stop reading this document and learn how to
do OpenID Connect in your programming language.)

3. If you still want to use a Shibboleth proxy,
create an `attribute-map.xml` file with the attributes configured in the SP registry.

Now on to the hairy stuff:
## Environment variables don't transfer to other containers

Shibboleth is designed to pass the user attributes retrieved from the IdP
by setting them in environment variables.
In traditional web server setups, the `httpd` server process launches a CGI script or uses
something like `mod_php` to run the application being served.

**This does not transfer well into a containerised microservice architecture.**

If httpd + mod_shib is acting as a reverse proxy,
there isn't a straight-forward way for the application backend to know about
httpd's environment variables.

## You *can* use HTTP headers

Shibboleth supports transmitting user attributes in HTTP headers instead,
but this alternative is vulnerable to spoofing attacks and is discouraged by Shibboleth documentation.
Shibboleth does contain some heuristics to prevent header spoofing,
but it is not fool proof and has had vulnerabilities in the past.

Don't use headers if you can avoid it.
But if you do,
don't use the `ShibUseHeaders` directive.
Read [this page in the wiki](https://wiki.helsinki.fi/display/IAMasioita/Apache+httpd+ja+mod_shibilla+suojaus).
Basically, you should configure your httpd to overwrite specific browser-supplied headers
with values from environment variables set by `mod_shib`.

## If not headers, then what?

First,
[read the university's documentation on implementing single sign-on](https://wiki.helsinki.fi/pages/viewpage.action?pageId=197657102)
to gain an accurate overview of the university's offerings and restrictions
as well as your options.

Then either:

* Use a **SAML** or **OpenID Connect** library in your programming language of choice to implement
  your authentication directly in your application, or
* Talk to your backend using a protocol which supports passing environment variables with proxied requests. See below.

## `mod_proxy_*` tricks

The Apache web server comes with various `mod_proxy_*` modules,
some of which implement a protocol which supports passing environment variables.
You may have some success passing user attributes using one of these.

The container image `quay.io/tike/shibboleth-sp-httpd` comes with these relevant modules:

* mod_proxy.so
* mod_proxy_ajp.so
* mod_proxy_fcgi.so
* mod_proxy_http.so
* mod_proxy_http2.so
* mod_proxy_scgi.so
* mod_proxy_uwsgi.so
* mod_proxy_wstunnel.so

### AJP

The [`mod_proxy_ajp` module](https://httpd.apache.org/docs/2.4/mod/mod_proxy_ajp.html) (*Apache JServ Protocol*)
can be used to pass environment variables.
All environment variables prefixed `AJP_` are passed to the backend,
with the prefix automatically removed.
Adding the `AJP_` prefix to your variable names is left as an exercise to the reader.

### FastCGI

[`mod_proxy_fcgi`](https://httpd.apache.org/docs/2.4/mod/mod_proxy_fcgi.html) can pass environment variables.
The FastCGI protocol is widely implemented in various programming languages.

### WSGI

The Python ecosystem has a protocol called WSGI
which supports attaching environment variables to requests.
If you setup your Python backend to be served on a WSGI server such as `gunicorn` or `uwsgi`,
you can use the [`mod_proxy_uwsgi` module](https://httpd.apache.org/docs/2.4/mod/mod_proxy_uwsgi.html)
and something like the following httpd config snippet
to pass Shibboleth-authenticated traffic to your backend:

```
ProxyPass /securepath uwsgi://mybackend:myport/
```

## Further reading

Some links in no particular order:

* https://shibboleth.atlassian.net/wiki/spaces/SP3/pages/2065335311/AddAttribute
* https://shibboleth.atlassian.net/wiki/spaces/SP3/pages/2065335257/AttributeAccess
