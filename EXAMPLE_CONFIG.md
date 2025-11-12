# Example configuration

These are example objects for running this service in an Openshift project.

## User attributes

**This minimal example config deliberately omits handling any user attributes.**
Attributes are a bit of a complicated subject with many possible approaches.

*A very viable approach for a containerised environment is to actually not use Shibboleth at all.*

**If you need any user attributes (you probably do)**,
please read the [USING ATTRIBUTES](USING_ATTRIBUTES.md) document before doing anything else.

## Secrets

**Make sure you do not include these in your version control,
or if you do,
protect them with something like Ansible Vault or [SealedSecrets](https://devops.pages.helsinki.fi/guides/tike-container-platform/instructions/secrets.html#sealedsecrets)**

The Openshift Container Platforms used by TIKE have SealedSecrets installed. It is the preferable solution until we get actual Secrets Management platform.

[Documentation on Secrets.](https://kubernetes.io/docs/concepts/configuration/secret/)

```Yaml
apiVersion: v1
kind: Secret
metadata:
  name: shib-secrets
  namespace: my-project
  labels:
    app: my-app
type: Opaque
data:
  shib-cert.pem: # base64-encoded certificate file
  shib-key.pem: # base64-encoded key file
```

## ConfigMaps

ConfigMaps contain configuration files for the applications running in your Pods.

[Documentation on ConfigMaps.](https://kubernetes.io/docs/concepts/configuration/configmap/)

### shibd

```Yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: shib-config
  namespace: my-project
  labels:
    app: my-app
data:
  attribute-map.xml: |
    <Attributes xmlns="urn:mace:shibboleth:2.0:attribute-map" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <!-- any attributes your application needs from the IdP -->
    </Attributes>
  shibboleth2.xml: |
    <SPConfig xmlns="urn:mace:shibboleth:3.0:native:sp:config"
              xmlns:conf="urn:mace:shibboleth:3.0:native:sp:config"
              clockSkew="180">

        <OutOfProcess tranLogFormat="%u|%s|%IDP|%i|%ac|%t|%attr|%n|%b|%E|%S|%SS|%L|%UA|%a" logger="console.logger"/>

        <!-- IMPORTANT -->
        <TCPListener address="127.0.0.1" port="1600" acl="127.0.0.1"/>

        <ApplicationDefaults entityID="https://my-project.example.com/shibboleth"
                            REMOTE_USER="eppn" signing="true"
                            cipherSuites="DEFAULT:!EXP:!LOW:!aNULL:!eNULL:!DES:!IDEA:!SEED:!RC4:!3DES:!kRSA:!SSLv2:!SSLv3:!TLSv1:!TLSv1.1">

            <Sessions lifetime="28800" timeout="3600" relayState="ss:mem"
                      checkAddress="false" handlerSSL="true" cookieProps="; path=/; secure;HttpOnly"
                      redirectLimit="exact">

                <SSO entityID="https://login.helsinki.fi/shibboleth">SAML2</SSO>

                <Logout>SAML2 Local</Logout>

                <Handler type="MetadataGenerator" Location="/Metadata" signing="false"/>
                <Handler type="Status" Location="/Status" acl="127.0.0.1 ::1"/>
                <Handler type="Session" Location="/Session" showAttributeValues="true"/>
                <Handler type="DiscoveryFeed" Location="/DiscoFeed"/>
            </Sessions>

            <Errors supportContact="my-contact-address@helsinki.fi"
                    helpLocation="/about.html"
                    styleSheet="/shibboleth-sp/main.css"/>

            <MetadataProvider type="XML" reloadInterval="7200"
                              url="https://login.helsinki.fi/metadata/sign-hy-metadata.xml"
                              backingFilePath="/etc/shibboleth/metadata/sign-hy-metadata.xml">
                <!-- <MetadataFilter type="RequireValidUntil" maxValidityInterval="2419200"/> -->
                <MetadataFilter type="Signature" certificate="sign-login.helsinki.fi.crt"/>
            </MetadataProvider>

            <AttributeExtractor type="XML" validate="true" reloadChanges="false" path="attribute-map.xml"/>

            <AttributeFilter type="XML" validate="true" path="attribute-policy.xml"/>

            <CredentialResolver type="File" use="signing"
                                key="/shib-secrets/shib-key.pem" certificate="/shib-secrets/shib-cert.pem"/>
            <CredentialResolver type="File" use="encryption"
                                key="/shib-secrets/shib-key.pem" certificate="/shib-secrets/shib-cert.pem"/>

        </ApplicationDefaults>

        <SecurityPolicyProvider type="XML" validate="true" path="security-policy.xml"/>

        <ProtocolProvider type="XML" validate="true" reloadChanges="false" path="protocols.xml"/>

    </SPConfig>
```

#### protocols.xml hardening present in image

The default installation of shibd comes with great many protocols allowed in the `/etc/shibboleth/protocol.xml`, 
most of which are usually not needed in the default usage in University of Helsinki. So, this image is built 
with a more restricted version in order to limit the exposed attack surface. 
You can see the restricted version in this repo at `shibd/base_shibboleth_configs/protocols.xml`. 

If you need more protocols and services in there, you can edit the above configmap with 
entry `protocols.xml` in the data part and it will override the restricted protocols.xml present in the image. 
NOTE: This change will, if you mount the volumes as shown at the end of this deployment, reflect on the 
httpd container as well.  

Please make sure you don't make this change without reason, and understand that you need 
to be aware of and take full responsibility of the security implications yourself.

### httpd

```Yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: httpd-config
  namespace: my-project
  labels:
    app: my-app
data:
  myapp.conf: |
    # Apache is listening on :8080 but is actually hosted behind an HTTPS
    # reverse proxy provided by the Openshift Route. In order to produce correct
    # HTTPS self-referential URLs, we need to convince Apache to use this
    # exact ServerName at all times.
    ServerName https://my-openshift-route:443
    UseCanonicalName On

    # Enable proxying to an SSL backend
    SSLProxyEngine On

    # Make sure we talk to the backend with the correct Host header,
    # otherwise TLS certificate matching will fail
    ProxyPreserveHost Off

    # The root path requires an active authenticated session with Shibboleth
    <Location />
        AuthType shibboleth
        ShibRequestSetting requireSession 1
        Require valid-user
    </Location>

    # Don't proxy these paths used by Shibboleth to the backend
    ProxyPass "/Shibboleth.sso" !
    ProxyPass "/shibboleth-sp" !

    # If your backend is accessible at a URL on the public Internet or the university's
    # network, 'my-backend-address' takes the form of something like https://example.com/my-thing.
    #
    # If your backend is another Service in your Openshift project,
    # 'my-backend-address' will be something like http://name-of-backend-service:8080,
    # depending on the configuration of that Service.
    ProxyPass / my-backend-address
    ProxyPassReverse / my-backend-address
```

## Deployment

[Documentation on Deployments.](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)

The section `spec.template.spec.affinity` is strictly optional.
The `podAntiAffinity` stanza as demonstrated attempts to schedule the replica pods on separate cluster nodes to maximise fault tolerance.

```Yaml
kind: Deployment
apiVersion: apps.openshift.io/v1
metadata:
  name: my-app
  namespace: my-project
  labels:
    app: my-app
spec:
  replicas: 2 # Set desired pod count here. Load balancing is automatically handled by the Service.
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
        # disable-allow-same-namespace: "" # OPTIONAL. See further below for "NetworkPolicy opt-out"!
    spec:
      affinity: # optional!
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
            - weight: 100
              podAffinityTerm:
                labelSelector:
                  matchExpressions:
                    - key: app
                      operator: In
                      values:
                        - my-app
                topologyKey: kubernetes.io/hostname
      volumes:
        - name: shib-secrets
          secret:
            secretName: shib-secrets
        - name: shib-config
          configMap:
            name: shib-config
        - name: httpd-config
          configMap:
            name: httpd-config
      containers:
        - name: shibd
          ports:
            - containerPort: 1600
              protocol: TCP
          image: quay.io/tike/openshift-sp-shibd:test # change to :prod to have marginally more testing
          volumeMounts:
            - name: shib-secrets
              mountPath: /shib-secrets
              readOnly: true
            - name: shib-config
              mountPath: /shib-config
              readOnly: true
          imagePullPolicy: Always
        - name: httpd
          ports:
            - containerPort: 8080
              protocol: TCP
          image: quay.io/tike/openshift-sp-httpd:test # change to :prod to have marginally more testing
          volumeMounts:
            - name: shib-config
              mountPath: /shib-config
              readOnly: true
            - name: httpd-config
              mountPath: /opt/app-root/etc/httpd.d
              readOnly: true
          imagePullPolicy: Always
      restartPolicy: Always
```

## Service

A Service exposes your Pod for network traffic with other Pods.

[Documentation on Services.](https://kubernetes.io/docs/concepts/services-networking/service/)

```Yaml
kind: Service
apiVersion: v1
metadata:
  name: my-app
  namespace: my-project
  labels:
    app: my-app
spec:
  ports:
    - name: 8080-tcp
      protocol: TCP
      port: 8080
      targetPort: 8080
  selector:
    app: my-app
```

## Route

A Route exposes your app for network traffic from outside the Openshift cluster.

[Documentation on Routes.](https://docs.redhat.com/en/documentation/openshift_container_platform/4.16/html/networking/configuring-routes#configuring-default-certificate)

The Openshift clusters at the University of Helsinki are currently configured with two
Ingress Controllers: `apps` for traffic within the university's network, and `ext` for the public Internet.

You can also use a custom name for the `spec.host` value,
but then you must provide your own certificate and key in the Route.
See above for documentation.

Setting up a custom hostname for your OpenShift project is outside the scope of this document.
See [here](https://wiki.helsinki.fi/xwiki/bin/view/SO/Platforms/Container%20Platform/Instructions/Accessing%20your%20application/#HCustomhostnames).

```Yaml
kind: Route
apiVersion: route.openshift.io/v1
metadata:
  name: my-app
  namespace: my-project
  labels:
    app: my-app
    type: external # only if you use the "ext" Ingress
spec:
  host: "my-route-name.(apps|ext).cluster-name.k8s.it.helsinki.fi"
  to:
    kind: Service
    name: my-app
  port:
    targetPort: 8080-tcp
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
  wildcardPolicy: None
```

## NetworkPolicy opt-out (optional)

### Do I need to care?

Due to the way ingress traffic is handled in University of Helsinki's container platform, 
the httpd container does _things_ to set up the remote ip address to correctly correspond 
to the actual client outside the cluster. 
(see: [httpd/files/set_forwarded_remote_ip.conf](httpd/files/set_forwarded_remote_ip.conf)) 

This setup does open the possibility of an attacker hiding their actual IP address 
from httpd/shibd logs, _if they are able to connect from within the OpenShift cluster._ 
Practically this requires the attacker to connect from within your own OpenShift project 
(kubernetes namespace) or any project your project has explicitly stated to allow access 
in the NetworkPolicies. When any OpenShift project gets deployed into University of Helsinki 
container platform, we have set up default NetworkPolicy objects to deny access from any 
other projects, aside from the `openshift-ingress` and `openshift-monitoring` projects which 
are required to be allowed for the correct operation of the container platform. 
And lastly, there is a NetworkPolicy object `allow-same-namespace` that makes it so that 
pods in the same project can connect to each other, since this is typically the expected 
behaviour.

Essentially, this means the attacker has to access your httpd from within the same project. 
If we leave out the possibility of an attacker having credentials to create their own pods 
(in which case all hope is lost anyways), the attacker has had to have access through 
one of your existing pods.

### I still want to prevent that possibility!

_**Due to the way NetworkPolicies stacking works, there is NO way to override allowing traffic into a pod, by making a new NetworkPolicy to disallow it.**_

Also, while it is technically possible for project admins to edit or delete the networkpolicy objects, the CI/CD set up by cluster administration will overwrite all your changes promptly.

The `allow-same-namespace` NetworkPolicy, however, has the following part in it:
```Yaml
...
spec:
  podSelector:
    matchExpressions:
    - key: disable-allow-same-namespace
      operator: DoesNotExist
...
```

And this means that any pod that includes the label `disable-allow-same-namespace=` (no key-value, just the string as the key) will be excluded from allowing inbound connections from other pods in your project. Do note though, if you then want more fine-grained control of a subset of your otherwise isolated pods to be able to talk to each other, you need to write your own NetworkPolicies to do that. Note, disabling incoming traffic to a pod does not prevent the pod itself connecting to other pods. This is fortunate as it allows the Apache ProxyPass directive to work even if the backend service is outside the pod.

Documentation: 
* [Network Policies at kubernetes docs](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
* [Labels and Selectors at kubernetes docs](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/)
* [Network Policies at University of Helsinki container platform docs](https://wiki.helsinki.fi/xwiki/bin/view/SO/Platforms/Container%20Platform/Instructions/Accessing%20your%20application/#HNetworkPolicies)
