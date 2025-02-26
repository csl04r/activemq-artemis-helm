# activemq-artemis

![Version: 0.8.0](https://img.shields.io/badge/Version-0.8.0-informational?style=flat-square) ![AppVersion: 2.39.0.11](https://img.shields.io/badge/AppVersion-2.39.0.11-informational?style=flat-square)

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
| core | object | `{"criticalAnalyzerPolicy":"SHUTDOWN"}` | additional core settings. Key, values are automatically expanded |
| core.criticalAnalyzerPolicy | string | `"SHUTDOWN"` | how to behave on critical errors detected, see https://activemq.apache.org/components/artemis/documentation/latest/critical-analysis.html |
| debugger.enabled | bool | `false` | if `true` starts the JVM with arguments to allow remote debugging |
| debugger.port | int | `8000` | the port to listen for remote debugging connections |
| image.pullPolicy | string | `"IfNotPresent"` |  |
| image.pullSecrets | list | `[]` |  |
| image.repository | string | `"docker.artifactory.sherwin.com/sherwin-williams-co/activemq-shw-extensions"` | required value to identify the image |
| image.tag | string | `""` | required value to identify the image |
| javaArgs | string | `"-XX:AutoBoxCacheMax=20000  -XX:+PrintClassHistogram  -XX:+UseG1GC  -XX:+UseStringDeduplication  -Xms512M  -Xmx512M  -Dhawtio.disableProxy=true  -Dhawtio.realm=activemq  -Dhawtio.offline=true  -Dhawtio.rolePrincipalClasses=org.apache.activemq.artemis.spi.core.security.jaas.RolePrincipal  -Dhawtio.http.strictTransportSecurity=max-age=31536000;includeSubDomains;preload  -Djolokia.policyLocation=/var/lib/artemis-instance/etc/jolokia-access.xml  -Dlog4j2.disableJmx=true  --add-opens java.base/jdk.internal.misc=ALL-UNNAMED"` | JVM arguments to include on the artemis server command line |
| metrics.enabled | bool | `true` | if `true` export prometheus metrics |
| metrics.serviceMonitor.enabled | bool | `false` | if `true` and metrics.enabled `true` then deploy service monitor |
| metrics.serviceMonitor.interval | string | `"10s"` | Prometheus scraping interval |
| metrics.serviceMonitor.namespace | string | `"monitoring"` | namespace where serviceMonitor is deployed |
| metrics.serviceMonitor.path | string | `"/metrics"` | Prometheus scraping path |
| nodeSelector | object | `{}` | allows setting security context for the container: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-pod containerSecurityContext: |
| persistence.accessModes | list | `["ReadWriteOnce"]` | used to build the PVC for the stateful set |
| persistence.enabled | bool | `true` | if true, then use persistent storage (recommended for production) |
| persistence.storageClassName | string | `"longhorn"` | used to build the PVC for teh stateful set |
| persistence.storageSize | string | `"8Gi"` | used to build the PVC for the stateful set |
| readinessProbe.initialDelaySeconds | int | `5` |  |
| readinessProbe.periodSeconds | int | `10` |  |
| readinessProbe.tcpSocket.port | string | `"netty"` |  |
| replicaCount | int | `1` | number of replicas in the stateful set. Do not set value greater than 1 unless you have a good reason |
| resources.limits.memory | string | `"794Mi"` |  |
| resources.requests.cpu | string | `"100m"` |  |
| resources.requests.memory | string | `"794Mi"` |  |
| security.kubernetes | object | `{"clients":[{"fullyQualifiedServiceAccountName":"system:serviceaccount:our-namespace:our-app","name":"OURAPP"}],"enabled":true,"roleAliases":{"some-amq-role":["system:serviceaccount:shw-na-pos:pol","system:serviceaccount:shw-na-pos:shercolor"]}}` | security configuration for clients running in the same Kubernetes cluster |
| security.kubernetes.clients[0] | object | `{"fullyQualifiedServiceAccountName":"system:serviceaccount:our-namespace:our-app","name":"OURAPP"}` | moniker for a known application that will connect from the same k8s cluster, used to create an AMQ role and destination prefix |
| security.kubernetes.clients[0].fullyQualifiedServiceAccountName | string | `"system:serviceaccount:our-namespace:our-app"` | the fully qualified service account name to acquire this AMQ role |
| security.kubernetes.enabled | bool | `true` | if `true` allow kubernetes service account token authentication and authorization |
| security.kubernetes.roleAliases | object | `{"some-amq-role":["system:serviceaccount:shw-na-pos:pol","system:serviceaccount:shw-na-pos:shercolor"]}` | maps ActiveMQ roles to a list of k8s principals |
| security.kubernetes.roleAliases.some-amq-role | list | `["system:serviceaccount:shw-na-pos:pol","system:serviceaccount:shw-na-pos:shercolor"]` | name of the ActiveMQ role to assign |
| security.kubernetes.roleAliases.some-amq-role[0] | string | `"system:serviceaccount:shw-na-pos:pol"` | list of k8s prinicpals to get the above ActiveMQ role |
| security.oauth2.audience | string | `"8bddbe55-946d-4033-8832-a1e752e97709"` | audience in JWT which identifies this group of ActiveMQ services |
| security.oauth2.enabled | bool | `true` | if `true` use OAuth2 JWT token authentication and authorization |
| security.oauth2.issuerUrl | string | `"https://login.microsoftonline.com/44b79a67-d972-49ba-9167-8eb05f754a1a/v2.0"` | URL of the OAuth2 issuer |
| security.oauth2.jaasModule | string | `"shw.activemq.extension.security.OAuth2LoginModule"` | LoginModule implementation class |
| security.oauth2.roleAliases | object | `{"some-amq-role":["CCN.BANKCARD.INFO","CCN.STORE.INFO"]}` | maps JWT roles to ActiveMQ roles. The ActiveMQ roles are the keys which take a list of JWT roles to which to grant the ActiveMQ role. |
| security.oauth2.roleAliases.some-amq-role | list | `["CCN.BANKCARD.INFO","CCN.STORE.INFO"]` | the ActiveMQ role to assign to the subject presenting the JWT |
| security.oauth2.roleAliases.some-amq-role[0] | string | `"CCN.BANKCARD.INFO"` | elements that, when any are present in the JWT, will qualify the JWT presenter to get the above ActiveMQ role |
| security.oauth2.rolesClaimName | string | `"roles"` | name of claim in the JWT containing strings to alias to an ActiveMQ role |
| security.oauth2.tenantId | string | `"44b79a67-d972-49ba-9167-8eb05f754a1a"` | In Microsoft Entra, the tenant ID in use |
| tls.enabled | bool | `true` | if `true`, will create a self-signed certificate and require remote connections to use TLS, i.e. by adding `?sslEnabled=true;trustAll=true` to the broker connection URL |
| tls.parameters | object | `{"keyStoreAlias":"server","keyStorePassword":"securepass","keyStorePath":"/var/lib/artemis-instance/tls/server-keystore.p12","keyStoreType":"PKCS12","sslEnabled":"true","trustStorePassword":"securepass","trustStorePath":"/var/lib/artemis-instance/tls/server-ca-truststore.p12","trustStoreType":"PKCS12"}` | a map of name-value pairs to be converted into the form n1=v1;n2=v2 and appended to broker acceptor connection URLs |
| tls.parameters.keyStoreAlias | string | `"server"` | alias in the keystore for the key & cert |
| tls.parameters.keyStorePassword | string | `"securepass"` | password for the keystore |
| tls.parameters.keyStorePath | string | `"/var/lib/artemis-instance/tls/server-keystore.p12"` | keystore holding key & cert for the broker |
| tls.parameters.keyStoreType | string | `"PKCS12"` | type of keystore |
| tls.parameters.sslEnabled | string | `"true"` | whether to use SSL/TLS |
| tls.parameters.trustStorePassword | string | `"securepass"` | password for the truststore |
| tls.parameters.trustStorePath | string | `"/var/lib/artemis-instance/tls/server-ca-truststore.p12"` | truststore holding CA certs for the broker |
| tls.parameters.trustStoreType | string | `"PKCS12"` | type of truststore |
| tolerations | list | `[]` |  |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
