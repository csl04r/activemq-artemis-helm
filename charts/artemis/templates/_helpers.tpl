{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "artemis.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "artemis.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create a secret name based on the configuration, if it is auto-generated or preexisting
*/}}
{{- define "artemis.secretname" -}}
{{- if (.Values.auth).existingSecret -}}
{{- .Values.auth.existingSecret -}}
{{- else -}}
{{- include "artemis.fullname" . }}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "artemis.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "artemis.labels" -}}
app.kubernetes.io/name: {{ include "artemis.name" . }}
helm.sh/chart: {{ include "artemis.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}


{{- define "artemis.labels.live" -}}
{{ include "artemis.labels" . }}
{{- if (.Values.ha).enabled }}
app.kubernetes.io/ha: live
{{- end }}
{{- end -}}

{{- define "artemis.labels.backup" -}}
{{ include "artemis.labels" . }}
app.kubernetes.io/ha: backup
{{- end -}}

{{- define "artemis.statefulset.spec" -}}
{{ $fullname := include "artemis.fullname" . }}
{{ $shwCostCenter := (.Values.global).shwCostCenter | default "XXXXXX" }}
initContainers:

- name: setup-broker
  image: {{ required "image repository is required" .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}
  imagePullPolicy: {{ .Values.image.pullPolicy}}
  workingDir: /var/lib/artemis-instance
  command:
    - bash
    - /tmp/scripts/setup-broker.sh
  env:
    - name: SHW_COST_CENTER
      value: {{ (.Values.global).shwCostCenter | default "XXXXXX"}}
    - name: ARTEMIS_PASSWORD
      valueFrom:
        secretKeyRef:
          name: {{ include "artemis.secretname" . }}
          key: clientPassword

  volumeMounts:
    - name: scripts
      mountPath: /tmp/scripts
    - name: certs
      mountPath: /certs
    - name: instance
      mountPath: /var/lib/artemis-instance
    - name: overrides
      mountPath: /var/lib/artemis-instance/etc-override

containers:
- name: activemq-artemis
  workingDir: /var/lib/artemis-instance
  command:
{{- if .Values.debugStatefulSet }}
    - sleep
    - infinity
{{- else }}
  - ./bin/artemis
  - run
{{- end }}
  image: {{ required "image repository is required" .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}
  imagePullPolicy: {{ .Values.image.pullPolicy}}
  resources:
    {{- toYaml .Values.resources | nindent 4 }}
  ports:
  {{- if (.Values.debugger).enabled }}
  - containerPort: {{ .Values.debugger.port }}
    name: jdwp
    {{- end }}
  - containerPort: 61616
    name: netty
  - containerPort: 5672
    name: amqp
  - containerPort: 61613
    name: stomp
  - containerPort: 1883
    name: mqtt
  - containerPort: 7800
    name: jgroups
  - containerPort: 8888
    name: kubeping
  - containerPort: 8161
    name: http
  {{- if .Values.metrics.enabled }}
  - containerPort: 9404
    name: prometheus
  {{- end }}
  readinessProbe:
  {{- if .Values.readinessProbe }}
    {{- toYaml .Values.readinessProbe | nindent 4 }}
  {{- end }}
  {{- if .Values.livenessProbe }}
  livenessProbe:
    {{- toYaml .Values.livenessProbe | nindent 4 }}
  {{- end }}
  env:
  {{- if (.Values.debugger).enabled }}
    - name: DEBUG_ARGS
      value: -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:{{.Values.debugger.port}}
  {{- end }}
    - name: JAVA_ARGS
      value: "{{ .Values.javaArgs }}"
    - name: ARTEMIS_INSTANCE_ETC_URI
      value: file:///var/lib/artemis-instance/etc/
    - name: ARTEMIS_USERNAME
      value: {{ (.Values.auth).clientUser | default "artemis" | quote }}
    - name: ARTEMIS_PASSWORD
      valueFrom:
        secretKeyRef:
          name: {{ include "artemis.secretname" . }}
          key: clientPassword
    - name: BROKER_CONFIG_CLUSTER_PASSWORD
      valueFrom:
        secretKeyRef:
            name: {{ include "artemis.secretname" . }}
            key: clusterPassword
    - name: ENABLE_JMX_EXPORTER
      value: {{ .Values.metrics.enabled | quote }}
    - name: SHW_COST_CENTER
      value: {{ (.Values.global).shwCostCenter | default "XXXXXX"}}
  volumeMounts:
  - name: tls
    mountPath: /var/lib/artemis-instance/tls
  - name: instance
    mountPath: /var/lib/artemis-instance
  - name: data
    mountPath: /var/lib/artemis-instance/data
  - name: overrides
    mountPath: /var/lib/artemis-instance/etc-override
  - name: hawtio
    mountPath: /opt/activemq-artemis/web/console.war/hawtconfig.json
    subPath: hawtconfig.json
serviceAccountName: {{ include "artemis.fullname" . }}
{{- if .Values.podSecurityContext }}
securityContext:
  {{- toYaml .Values.podSecurityContext | nindent 2 }}
{{- end }}
{{- with .Values.nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.affinity }}
affinity:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.tolerations }}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.image.pullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
volumes:
- name: hawtio
  configMap:
    name: {{ include "artemis.fullname" . }}-hawtio
- name: scripts
  configMap:
    name: {{ include "artemis.fullname" . }}-scripts
- name: certs
  configMap:
    name: {{ include "artemis.fullname" . }}-certs
- name: tls
  secret:
    secretName: {{ include "artemis.fullname" . }}-tls
- name: instance
  emptyDir: {}
{{- if not .Values.persistence.enabled }}
- name: data
  emptyDir: {}
{{- end }}
- name: overrides
  configMap:
    name: {{ include "artemis.fullname" . }}-override
{{- end -}}

{{- define "artemis.statefulset.volumeclaim" -}}
{{- if .Values.persistence.enabled }}
volumeClaimTemplates:
- metadata:
    name: data
  spec:
    accessModes:
{{ toYaml .Values.persistence.accessModes | indent 6 }}
    {{- if .Values.persistence.storageClassName }}
    storageClassName: {{ .Values.persistence.storageClassName }}
    {{- end }}
    resources:
      requests:
        storage: {{ .Values.persistence.storageSize }}
  {{- end }}
{{- end -}}


{{- define "tls.params" -}}
  {{- if (.Values.tls).enabled -}}
    {{- range $key, $val := .Values.tls.parameters -}}
;{{- $key }}={{- $val -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- define "artemis.broker.xml" -}}
<?xml version='1.0'?>
<!--
Licensed to the Apache Software Foundation (ASF) under one
or more contributor license agreements.  See the NOTICE file
distributed with this work for additional information
regarding copyright ownership.  The ASF licenses this file
to you under the Apache License, Version 2.0 (the
"License"); you may not use this file except in compliance
with the License.  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing,
software distributed under the License is distributed on an
"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
KIND, either express or implied.  See the License for the
specific language governing permissions and limitations
under the License.
-->

<configuration xmlns="urn:activemq"
               xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
               xmlns:xi="http://www.w3.org/2001/XInclude"
               xsi:schemaLocation="urn:activemq /schema/artemis-configuration.xsd">

   <core xmlns="urn:activemq:core" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="urn:activemq:core ">

      <name>0.0.0.0</name>


      <persistence-enabled>true</persistence-enabled>

      <!-- It is recommended to keep this value as 1, maximizing the number of records stored about redeliveries.
           However if you must preserve state of individual redeliveries, you may increase this value or set it to -1 (infinite). -->
      <max-redelivery-records>1</max-redelivery-records>

      <!-- this could be ASYNCIO, MAPPED, NIO
           ASYNCIO: Linux Libaio
           MAPPED: mmap files
           NIO: Plain Java Files
       -->
      <journal-type>NIO</journal-type>

      <paging-directory>data/paging</paging-directory>

      <bindings-directory>data/bindings</bindings-directory>

      <journal-directory>data/journal</journal-directory>

      <large-messages-directory>data/large-messages</large-messages-directory>


      <!-- if you want to retain your journal uncomment this following configuration.

      This will allow your system to keep 7 days of your data, up to 10G. Tweak it accordingly to your use case and capacity.

      it is recommended to use a separate storage unit from the journal for performance considerations.

      <journal-retention-directory period="7" unit="DAYS" storage-limit="10G">data/retention</journal-retention-directory>

      You can also enable retention by using the argument journal-retention on the `artemis create` command -->



      <journal-datasync>true</journal-datasync>

      <journal-min-files>2</journal-min-files>

      <journal-pool-files>10</journal-pool-files>

      <journal-device-block-size>4096</journal-device-block-size>

      <journal-file-size>10M</journal-file-size>

      <!--
       This value was determined through a calculation.
       Your system could perform 12.5 writes per millisecond
       on the current journal configuration.
       That translates as a sync write every 80000 nanoseconds.

       Note: If you specify 0 the system will perform writes directly to the disk.
             We recommend this to be 0 if you are using journalType=MAPPED and journal-datasync=false.
      -->
      <journal-buffer-timeout>80000</journal-buffer-timeout>


      <!--
        When using ASYNCIO, this will determine the writing queue depth for libaio.
       -->
      <journal-max-io>1</journal-max-io>
      <!--
        You can verify the network health of a particular NIC by specifying the <network-check-NIC> element.
         <network-check-NIC>theNicName</network-check-NIC>
        -->

      <!--
        Use this to use an HTTP server to validate the network
         <network-check-URL-list>http://www.apache.org</network-check-URL-list> -->

      <!-- <network-check-period>10000</network-check-period> -->
      <!-- <network-check-timeout>1000</network-check-timeout> -->

      <!-- this is a comma separated list, no spaces, just DNS or IPs
           it should accept IPV6

           Warning: Make sure you understand your network topology as this is meant to validate if your network is valid.
                    Using IPs that could eventually disappear or be partially visible may defeat the purpose.
                    You can use a list of multiple IPs, and if any successful ping will make the server OK to continue running -->
      <!-- <network-check-list>10.0.0.1</network-check-list> -->

      <!-- use this to customize the ping used for ipv4 addresses -->
      <!-- <network-check-ping-command>ping -c 1 -t %d %s</network-check-ping-command> -->

      <!-- use this to customize the ping used for ipv6 addresses -->
      <!-- <network-check-ping6-command>ping6 -c 1 %2$s</network-check-ping6-command> -->




      <!-- how often we are looking for how many bytes are being used on the disk in ms -->
      <disk-scan-period>5000</disk-scan-period>

      <!-- once the disk hits this limit the system will block, or close the connection in certain protocols
           that won't support flow control. -->
      <max-disk-usage>90</max-disk-usage>

      <!-- should the broker detect dead locks and other issues -->
      <critical-analyzer>true</critical-analyzer>

      <critical-analyzer-timeout>120000</critical-analyzer-timeout>

      <critical-analyzer-check-period>60000</critical-analyzer-check-period>

      <critical-analyzer-policy>HALT</critical-analyzer-policy>


      <page-sync-timeout>80000</page-sync-timeout>


      <!-- the system will enter into page mode once you hit this limit. This is an estimate in bytes of how much the messages are using in memory

      The system will use half of the available memory (-Xmx) by default for the global-max-size.
      You may specify a different value here if you need to customize it to your needs.

      <global-max-size>100Mb</global-max-size> -->

      <!-- the maximum number of messages accepted before entering full address mode.
           if global-max-size is specified the full address mode will be specified by whatever hits it first. -->
      <global-max-messages>-1</global-max-messages>

      <acceptors>

         <!-- useEpoll means: it will use Netty epoll if you are on a system (Linux) that supports it -->
         <!-- amqpCredits: The number of credits sent to AMQP producers -->
         <!-- amqpLowCredits: The server will send the # credits specified at amqpCredits at this low mark -->
         <!-- amqpDuplicateDetection: If you are not using duplicate detection, set this to false
                                      as duplicate detection requires applicationProperties to be parsed on the server. -->
         <!-- amqpMinLargeMessageSize: Determines how many bytes are considered large, so we start using files to hold their data.
                                       default: 102400, -1 would mean to disable large message control -->

         <!-- Note: If an acceptor needs to be compatible with HornetQ and/or Artemis 1.x clients add
                    "anycastPrefix=jms.queue.;multicastPrefix=jms.topic." to the acceptor url.
                    See https://issues.apache.org/jira/browse/ARTEMIS-1644 for more information. -->


         <!-- Acceptor for every supported protocol -->
        <acceptor name="artemis-tls">
            tcp://0.0.0.0:61616?tcpSendBufferSize=1048576;tcpReceiveBufferSize=1048576;amqpMinLargeMessageSize=102400;protocols=CORE,AMQP,STOMP,HORNETQ,MQTT,OPENWIRE;useEpoll=true;amqpCredits=1000;amqpLowCredits=300;amqpDuplicateDetection=true;supportAdvisory=false;suppressInternalManagementObjects=false{{- include "tls.params" . -}}
        </acceptor>


         <!-- AMQP Acceptor.  Listens on default AMQP port for AMQP traffic.-->
         <acceptor name="amqp">tcp://0.0.0.0:5672?tcpSendBufferSize=1048576;tcpReceiveBufferSize=1048576;protocols=AMQP;useEpoll=true;amqpCredits=1000;amqpLowCredits=300;amqpMinLargeMessageSize=102400;amqpDuplicateDetection=true{{- include "tls.params" . -}}
        </acceptor>

         <!-- STOMP Acceptor. -->
         <acceptor name="stomp">tcp://0.0.0.0:61613?tcpSendBufferSize=1048576;tcpReceiveBufferSize=1048576;protocols=STOMP;useEpoll=true{{- include "tls.params" . -}}
        </acceptor>

         <!-- HornetQ Compatibility Acceptor.  Enables HornetQ Core and STOMP for legacy HornetQ clients. -->
         <acceptor name="hornetq">tcp://0.0.0.0:5445?anycastPrefix=jms.queue.;multicastPrefix=jms.topic.;protocols=HORNETQ,STOMP;useEpoll=true{{- include "tls.params" . -}}
        </acceptor>

         <!-- MQTT Acceptor -->
         <acceptor name="mqtt">tcp://0.0.0.0:1883?tcpSendBufferSize=1048576;tcpReceiveBufferSize=1048576;protocols=MQTT;useEpoll=true{{- include "tls.params" . -}}
        </acceptor>

      </acceptors>


      <security-settings>
         <security-setting match="#">
            <permission type="createNonDurableQueue" roles="amq"/>
            <permission type="deleteNonDurableQueue" roles="amq"/>
            <permission type="createDurableQueue" roles="amq"/>
            <permission type="deleteDurableQueue" roles="amq"/>
            <permission type="createAddress" roles="amq"/>
            <permission type="deleteAddress" roles="amq"/>
            <permission type="consume" roles="amq"/>
            <permission type="browse" roles="amq"/>
            <permission type="send" roles="amq"/>
            <!-- we need this otherwise ./artemis data imp wouldn't work -->
            <permission type="manage" roles="amq"/>
         </security-setting>
         <!-- "global.#" queues are wide open -->
         <security-setting match="global.#">
            <permission type="createNonDurableQueue" roles="amq,system:authenticated,global"/>
            <permission type="deleteNonDurableQueue" roles="amq,system:authenticated,global"/>
            <permission type="createDurableQueue" roles="amq,system:authenticated,global"/>
            <permission type="deleteDurableQueue" roles="amq,system:authenticated,global"/>
            <permission type="createAddress" roles="amq,system:authenticated,global"/>
            <permission type="deleteAddress" roles="amq,system:authenticated,global"/>
            <permission type="consume" roles="amq,system:authenticated,global"/>
            <permission type="browse" roles="amq,system:authenticated,global"/>
            <permission type="send" roles="amq,system:authenticated,global"/>
            <!-- we need this otherwise ./artemis data imp wouldn't work -->
            <permission type="manage" roles="amq,system:authenticated,global"/>
         </security-setting>
         {{- with ((.Values.security).kubernetes) }}
         {{- if .enabled }}
         {{- range  $ix, $entry := .clients }}
         <security-setting match="{{ $entry.name }}.#">
            <permission type="createNonDurableQueue" roles="amq,{{ $entry.name  }}"/>
            <permission type="deleteNonDurableQueue" roles="amq,{{ $entry.name  }}"/>
            <permission type="createDurableQueue" roles="amq,{{ $entry.name  }}"/>
            <permission type="deleteDurableQueue" roles="amq,{{ $entry.name  }}"/>
            <permission type="createAddress" roles="amq,{{ $entry.name  }}"/>
            <permission type="deleteAddress" roles="amq,{{ $entry.name  }}"/>
            <permission type="consume" roles="amq,{{ $entry.name  }}"/>
            <permission type="browse" roles="amq,{{ $entry.name  }}"/>
            <permission type="send" roles="amq,{{ $entry.name  }}"/>
            <permission type="manage" roles="amq,{{ $entry.name  }}"/>
         </security-setting>
         {{- end }}
         {{- end }}
         {{- end }}
      </security-settings>

      <address-settings>
         <!-- if you define auto-create on certain queues, management has to be auto-create -->
         <address-setting match="activemq.management#">
            <dead-letter-address>DLQ</dead-letter-address>
            <expiry-address>ExpiryQueue</expiry-address>
            <redelivery-delay>0</redelivery-delay>
            <!-- with -1 only the global-max-size is in use for limiting -->
            <max-size-bytes>-1</max-size-bytes>
            <message-counter-history-day-limit>10</message-counter-history-day-limit>
            <address-full-policy>PAGE</address-full-policy>
            <auto-create-queues>true</auto-create-queues>
            <auto-create-addresses>true</auto-create-addresses>
         </address-setting>
         <!--default for catch all-->
         <address-setting match="#">
            <dead-letter-address>DLQ</dead-letter-address>
            <expiry-address>ExpiryQueue</expiry-address>
            <redelivery-delay>500</redelivery-delay>
            <redelivery-delay-multiplier>2.0</redelivery-delay-multiplier>
            <max-redelivery-delay>300000</max-redelivery-delay>
            <!-- infinite redelivery -->
            <max-delivery-attempts>-1</max-delivery-attempts>
            <message-counter-history-day-limit>10</message-counter-history-day-limit>
            <address-full-policy>PAGE</address-full-policy>
            <auto-create-queues>true</auto-create-queues>
            <auto-create-addresses>true</auto-create-addresses>
            <auto-delete-queues>false</auto-delete-queues>
            <auto-delete-addresses>false</auto-delete-addresses>

            <!-- The size of each page file -->
            <page-size-bytes>10M</page-size-bytes>

            <!-- When we start applying the address-full-policy, e.g paging -->
            <!-- Both are disabled by default, which means we will use the global-max-size/global-max-messages  -->
            <max-size-bytes>-1</max-size-bytes>
            <max-size-messages>-1</max-size-messages>

            <!-- When we read from paging into queues (memory) -->

            <max-read-page-messages>-1</max-read-page-messages>
            <max-read-page-bytes>20M</max-read-page-bytes>

            <!-- Limit on paging capacity before starting to throw errors -->

            <page-limit-bytes>-1</page-limit-bytes>
            <page-limit-messages>-1</page-limit-messages>
          </address-setting>
      </address-settings>

      <addresses>
         <address name="DLQ">
            <anycast>
               <queue name="DLQ" />
            </anycast>
         </address>
         <address name="ExpiryQueue">
            <anycast>
               <queue name="ExpiryQueue" />
            </anycast>
         </address>
      </addresses>

      <!-- Uncomment the following if you want to use the Standard LoggingActiveMQServerPlugin pluging to log in events
      <broker-plugins>
         <broker-plugin class-name="org.apache.activemq.artemis.core.server.plugin.impl.LoggingActiveMQServerPlugin">
            <property key="LOG_ALL_EVENTS" value="true"/>
            <property key="LOG_CONNECTION_EVENTS" value="true"/>
            <property key="LOG_SESSION_EVENTS" value="true"/>
            <property key="LOG_CONSUMER_EVENTS" value="true"/>
            <property key="LOG_DELIVERING_EVENTS" value="true"/>
            <property key="LOG_SENDING_EVENTS" value="true"/>
            <property key="LOG_INTERNAL_EVENTS" value="true"/>
         </broker-plugin>
      </broker-plugins>
      -->

   </core>
</configuration>
{{- end -}}

{{- define "artemis.login.config" -}}
activemq {
   org.apache.activemq.artemis.spi.core.security.jaas.PropertiesLoginModule sufficient
       debug=true
       reload=true
       org.apache.activemq.jaas.properties.user="artemis-users.properties"
       org.apache.activemq.jaas.properties.role="artemis-roles.properties";
   {{- with (.Values.security).oauth2 }}
   {{- if .enabled }}
   {{.jaasModule }} sufficient
       debug=true
       audience="{{ required "audience is required" .audience }}"
       rolesClaimName="{{ .rolesClaimName | default "roles" }}"
       {{- if .tenantId }}
       tenantId="{{.tenantId}}"
       {{- end }}
       issuerUrl="{{ required "issuerUrl is required" .issuerUrl }}"
       reload=true
       shw.activemq.extension.security.oauth2.role="oauth2-role-aliases.properties";
       {{- end }}
   {{- end }}
   {{- with (.Values.security).kubernetes }}
   {{- if .enabled }}
   org.apache.activemq.artemis.spi.core.security.jaas.KubernetesLoginModule sufficient
       debug=true
       reload=true
       org.apache.activemq.jaas.kubernetes.role="k8s-roles.properties";
       {{- end }}
       {{- end }}
};
{{- end -}}

{{- define "artemis.oauth2.rolealiases" -}}

{{- end -}}

{{- define "artemis.psa" -}}
    {{- with .Values.podSecurityAdmission }}
        {{- if .enabled }}
# The per-mode level label indicates which policy level to apply for the mode.
# MODE must be one of `enforce`, `audit`, or `warn`.
# LEVEL must be one of `privileged`, `baseline`, or `restricted`.
pod-security.kubernetes.io/{{ .mode | default "enforce" }}: {{ .level | default "restricted" | quote }}

# Optional: per-mode version label that can be used to pin the policy to the
# version that shipped with a given Kubernetes minor version (for example v1.32).
# MODE must be one of `enforce`, `audit`, or `warn`.
# VERSION must be a valid Kubernetes minor version, or `latest`.
pod-security.kubernetes.io/{{ .mode | default "enforce" }}-version: {{ .version | default "latest" | quote }}
        {{- end }}
    {{- end }}
{{- end -}}

{{- define "artemis.serviceaccount" -}}
{{- end -}}