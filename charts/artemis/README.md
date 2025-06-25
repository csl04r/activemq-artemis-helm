# activemq-artemis

![Version: 1.10.1](https://img.shields.io/badge/Version-1.10.1-informational?style=flat-square) ![AppVersion: 2.41.0.1](https://img.shields.io/badge/AppVersion-2.41.0.1-informational?style=flat-square)

A Helm chart installing Apache ActiveMQ Artemis,
[forked](https://github.com/sherwin-williams-co/activemq-artemis-helm) from Device Insight GmbH

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Device Insight GmbH |  |  |
| Chad Lauritsen | <Chad.S.Lauritsen@sherwin.com> |  |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| addressSettings | list | `[{"match":"#","settings":{"deadLetterAddress":"DLQ","expiryAddress":"ExpiryQueue","messageCounterHistoryDayLimit":10}}]` | list of address settings to include in the broker.xml |
| addressSettings[0] | object | `{"match":"#","settings":{"deadLetterAddress":"DLQ","expiryAddress":"ExpiryQueue","messageCounterHistoryDayLimit":10}}` | pattern of address name to match, use `#` for wildcard |
| addressSettings[0].settings | object | `{"deadLetterAddress":"DLQ","expiryAddress":"ExpiryQueue","messageCounterHistoryDayLimit":10}` | settings to add to the address |
| addressSettings[0].settings.deadLetterAddress | string | `"DLQ"` | configures the address settings, see the artemis docs for details |
| addressSettings[0].settings.expiryAddress | string | `"ExpiryQueue"` | configures the address settings, see the artemis docs for details |
| addressSettings[0].settings.messageCounterHistoryDayLimit | int | `10` | configures the address settings, see the artemis docs for details |
| addresses | list | `[{"name":"DLQ"},{"name":"ExpiryQueue"}]` | list of named address (JMS destinations) to pre-populate in the broker |
| affinity | object | `{}` |  |
| appRoleSecrets | object | `{"roleId":"","secretId":""}` | secret values for AppRole authentication to HashiCorp vault. These are used to sign a CSR and get a valid cert for the broker. |
| appRoleSecrets.roleId | string | `""` | the role ID for the AppRole |
| appRoleSecrets.secretId | string | `""` | the secret ID for the AppRole |
| core | object | `{"criticalAnalyzerPolicy":"SHUTDOWN"}` | additional core settings. Key, values are automatically expanded |
| core.criticalAnalyzerPolicy | string | `"SHUTDOWN"` | how to behave on critical errors detected, see https://activemq.apache.org/components/artemis/documentation/latest/critical-analysis.html |
| debugger | object | `{"enabled":false,"port":8000}` | type of truststore    trustStoreType: PKCS12 |
| debugger.enabled | bool | `false` | if `true` starts the JVM with arguments to allow remote debugging |
| debugger.port | int | `8000` | the port to listen for remote debugging connections |
| image.pullPolicy | string | `"IfNotPresent"` |  |
| image.pullSecrets | list | `[]` |  |
| image.repository | string | `"docker.artifactory.sherwin.com/sherwin-williams-co/activemq-shw-extensions"` | required value to identify the image |
| image.tag | string | `""` | required value to identify the image |
| javaArgs | string | `"-XX:AutoBoxCacheMax=20000  -XX:+PrintClassHistogram  -XX:+UseG1GC  -XX:+UseStringDeduplication  -Xms512M  -Xmx512M  -Dhawtio.contextPath=/console  -Dhawtio.proxy.basePath=/console/jolokia  -Dhawtio.disableProxy=true  -Dhawtio.realm=activemq  -Dhawtio.offline=true  -Dhawtio.rolePrincipalClasses=org.apache.activemq.artemis.spi.core.security.jaas.RolePrincipal  -Dhawtio.http.strictTransportSecurity=max-age=31536000;includeSubDomains;preload  -Djolokia.policyLocation=file:///var/lib/artemis-instance/etc/jolokia-access.xml  -Dlog4j2.disableJmx=true  --add-opens java.base/jdk.internal.misc=ALL-UNNAMED"` | JVM arguments to include on the artemis server command line |
| metrics.enabled | bool | `true` | if `true` export prometheus metrics |
| metrics.serviceMonitor.enabled | bool | `false` | if `true` and metrics.enabled `true` then deploy service monitor |
| metrics.serviceMonitor.interval | string | `"10s"` | Prometheus scraping interval |
| metrics.serviceMonitor.namespace | string | `"monitoring"` | namespace where serviceMonitor is deployed |
| metrics.serviceMonitor.path | string | `"/metrics"` | Prometheus scraping path |
| nodeSelector | object | `{}` |  |
| persistence.accessModes | list | `["ReadWriteOnce"]` | used to build the PVC for the stateful set |
| persistence.enabled | bool | `true` | if true, then use persistent storage (recommended for production) |
| persistence.storageClassName | string | `"longhorn"` | used to build the PVC for teh stateful set |
| persistence.storageSize | string | `"8Gi"` | used to build the PVC for the stateful set |
| podSecurityAdmission.enabled | bool | `true` | if `true` add a pod security policy admission annotations to the pod |
| podSecurityAdmission.level | string | `"restricted"` | must be one of `privileged`, `baseline`, or `restricted`. |
| podSecurityAdmission.mode | string | `"enforce"` | must be one of `enforce`, `audit`, or `warn` |
| podSecurityAdmission.version | string | `"latest"` | must be a valid Kubernetes minor version, or `latest` |
| podSecurityContext | object | `{"fsGroup":1001,"runAsGroup":1001,"runAsNonRoot":true,"runAsUser":1001}` | allows setting security context for the pod: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-pod |
| podSecurityContext.fsGroup | int | `1001` | group id of mounted volumes (must match runAsGroup for this to work) |
| podSecurityContext.runAsGroup | int | `1001` | the group id to use when running the container |
| podSecurityContext.runAsNonRoot | bool | `true` | if `true` run the container as a non-root user |
| podSecurityContext.runAsUser | int | `1001` | the user id to use when running the container |
| pycertmanager.enabled | bool | `true` | if `true` use [pycertmanager](https://github.com/sherwin-williams-co/pycertmanager) to manage the TLS certs and PCKS#12 keystore for the broker. If `false`, do it yourself some other way. TLS certs are required. |
| pycertmanager.image.repository | string | `"docker.artifactory.sherwin.com/sherwin-williams-co/pycertmanager"` |  |
| pycertmanager.image.tag | string | `"0.1.5"` |  |
| readinessProbe.initialDelaySeconds | int | `5` |  |
| readinessProbe.periodSeconds | int | `10` |  |
| readinessProbe.tcpSocket.port | string | `"netty"` |  |
| replicaCount | int | `1` | number of replicas in the stateful set. Do not set value greater than 1 unless you have a good reason |
| resources.limits.memory | string | `"794Mi"` |  |
| resources.requests.cpu | string | `"100m"` |  |
| resources.requests.memory | string | `"794Mi"` |  |
| security.kubernetes | object | `{"clients":[],"enabled":true,"roleAliases":{}}` | security configuration for clients running in the same Kubernetes cluster |
| security.kubernetes.enabled | bool | `true` | if `true` allow kubernetes service account token authentication and authorization |
| security.kubernetes.roleAliases | object | `{}` | maps ActiveMQ roles to a list of k8s principals |
| security.oauth2.audience | string | `"8bddbe55-946d-4033-8832-a1e752e97709"` | audience in JWT which identifies this group of ActiveMQ services |
| security.oauth2.enabled | bool | `true` | if `true` use OAuth2 JWT token authentication and authorization |
| security.oauth2.issuerUrl | string | `"https://login.microsoftonline.com/44b79a67-d972-49ba-9167-8eb05f754a1a/v2.0"` | URL of the OAuth2 issuer |
| security.oauth2.jaasModule | string | `"shw.activemq.extension.security.OAuth2LoginModule"` | LoginModule implementation class |
| security.oauth2.roleAliases | object | `{}` | maps JWT roles to ActiveMQ roles. The ActiveMQ roles are the keys which take a list of JWT roles to which to grant the ActiveMQ role. |
| security.oauth2.rolesClaimName | string | `"roles"` | name of claim in the JWT containing strings to alias to an ActiveMQ role |
| security.oauth2.tenantId | string | `"44b79a67-d972-49ba-9167-8eb05f754a1a"` | In Microsoft Entra, the tenant ID in use |
| service.loadBalancer.annotations."metallb.universe.tf/allow-shared-ip" | string | `"172.30.0.8"` |  |
| service.loadBalancer.annotations."metallb.universe.tf/ip-allocated-from-pool" | string | `"default-pool"` |  |
| tls.enabled | bool | `true` | if `true`, will create a self-signed certificate and require remote connections to use TLS, i.e. by adding `?sslEnabled=true;trustAll=true` to the broker connection URL |
| tls.parameters | object | `{"keyStoreAlias":"server","keyStorePassword":"securepass","keyStorePath":"/var/lib/artemis-instance/tls/tls.p12","keyStoreType":"PKCS12","sslEnabled":"true"}` | a map of name-value pairs to be converted into the form n1=v1;n2=v2 and appended to broker acceptor connection URLs |
| tls.parameters.keyStoreAlias | string | `"server"` | alias in the keystore for the key & cert |
| tls.parameters.keyStorePassword | string | `"securepass"` | password for the keystore |
| tls.parameters.keyStorePath | string | `"/var/lib/artemis-instance/tls/tls.p12"` | keystore holding key & cert for the broker |
| tls.parameters.keyStoreType | string | `"PKCS12"` | type of keystore |
| tls.parameters.sslEnabled | string | `"true"` | whether to use SSL/TLS |
| tolerations | list | `[]` |  |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
