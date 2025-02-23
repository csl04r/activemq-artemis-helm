#!/bin/bash
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

# The various SSL stores and certificates were created with the following commands:
# Requires use of JDK 8+ keytool command.
set -e

KEY_PASS=securepass
STORE_PASS=securepass
CA_VALIDITY=365000
VALIDITY=36500
LOCAL_CLIENT_NAMES="dns:localhost,ip:127.0.0.1"
LOCAL_SERVER_NAMES="dns:localhost,dns:localhost.localdomain,dns:artemis.localtest.me,ip:127.0.0.1"


mkdir -p tls
cd tls

# Clean up existing files
# -----------------------
rm -f *.crt *.csr openssl-* *.jceks *.jks *.p12 *.pem *.pemcfg

# Create a key and self-signed certificate for the CA, to sign server certificate requests and use for trust:
# ----------------------------------------------------------------------------------------------------
keytool -storetype pkcs12 -keystore server-ca-keystore.p12 -storepass $STORE_PASS -keypass $KEY_PASS -alias server-ca -genkey -keyalg "RSA" -keysize 2048 -dname "CN=ActiveMQ Artemis Server Certification Authority, OU=Artemis, O=ActiveMQ" -validity $CA_VALIDITY -ext bc:c=ca:true
# export the CA cert
keytool -storetype pkcs12 -keystore server-ca-keystore.p12 -storepass $STORE_PASS -alias server-ca -exportcert -rfc > server-ca.crt

# Create trust store with the server CA cert:
# -------------------------------------------------------
keytool -storetype pkcs12 -keystore server-ca-truststore.p12 -storepass $STORE_PASS -keypass $KEY_PASS -importcert -alias server-ca -file server-ca.crt -noprompt

# Create a key pair for the server
keytool -storetype pkcs12 -keystore server-keystore.p12 -storepass $STORE_PASS -keypass $KEY_PASS -alias server -genkey -keyalg "RSA" -keysize 2048 -dname "CN=ActiveMQ Artemis Server, OU=Artemis, O=ActiveMQ, L=AMQ, S=AMQ, C=AMQ" -validity $VALIDITY -ext bc=ca:false -ext eku=sA -ext "san=dns:server.artemis.activemq,$LOCAL_SERVER_NAMES"
# create CSR (certificate signing request)
keytool -storetype pkcs12 -keystore server-keystore.p12 -storepass $STORE_PASS -alias server -certreq -file server.csr
# sign the CSR with the CA
keytool -storetype pkcs12 -keystore server-ca-keystore.p12 -storepass $STORE_PASS -alias server-ca -gencert -rfc -infile server.csr -outfile server.crt -validity $VALIDITY -ext bc=ca:false -ext eku=sA -ext "san=dns:server.artemis.activemq,$LOCAL_SERVER_NAMES"
# load the  ca Cert into the broker keystore
keytool -storetype pkcs12 -keystore server-keystore.p12 -storepass $STORE_PASS -keypass $KEY_PASS -importcert -alias server-ca -file server-ca.crt -noprompt
# load the broker Cert into the broker keystore
keytool -storetype pkcs12 -keystore server-keystore.p12 -storepass $STORE_PASS -keypass $KEY_PASS -importcert -alias server -file server.crt

# Clean up working files
# -----------------------
rm -f *.crt *.csr openssl-*
