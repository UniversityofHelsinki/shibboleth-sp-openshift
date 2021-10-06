# Example configuration

These are example objects for running this service in an Openshift project.

## Secrets

**Make sure you do not include these in your version control,
or if you do,
protect them with something like Ansible Vault or [Helm secrets](https://github.com/jkroepke/helm-secrets)
([see also](https://wiki.helsinki.fi/display/SO/Helm+ja+salaisuuksienhallinta))!**

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
                      checkAddress="false" handlerSSL="false" cookieProps="http">

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
        # Put any required user attributes here
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

[Documentation on Deployments.](https://docs.openshift.com/container-platform/4.7/rest_api/workloads_apis/deployment-apps-v1.html)

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
          image: quay.io/tike/openshift-sp-shibd:latest
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
          image: quay.io/tike/openshift-sp-httpd:latest
          volumeMounts:
            - name: shib-secrets
              mountPath: /shib-secrets
              readOnly: true
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

[Documentation on Routes.](https://docs.openshift.com/container-platform/4.6/networking/routes/route-configuration.html)

The Openshift clusters at the University of Helsinki are currently configured with two
Ingress Controllers: `apps` for traffic within the university's network, and `ext` for the public Internet.

You can also use a custom name for the `spec.host` value,
but then you must provide your own certificate and key in the Route.
See above for documentation.

Setting up a custom hostname for your OpenShift project is outside the scope of this document.
See [here](https://wiki.helsinki.fi/pages/viewpage.action?pageId=364188115) in Finnish.

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
