#!/bin/bash

set -e

mkdir -p tls
cd tls

# Clean up working files on signal or exit
# -----------------------
trap 'echo INFO: cleaning up temp files in $PWD; rm -f *.csr openssl-*' EXIT

subject_alternate_names=(
# probably never used
  "dns:localhost"
  # bare pod name
  "dns:${POD_NAME:?not set}"
  # pod name with namespace
  "dns:${POD_NAME:?not set}.${POD_NAMESPACE:?not set}"
  # headless service
  "dns:${HELM_FULLNAME:?not set}.${POD_NAMESPACE:?not set}.svc.cluster.local"
  # load balancer, arbitrary DNS name
  "dns:${HELM_FULLNAME:?not set}.${SHW_COST_CENTER:?not set}-service.stores.sherwin.com"
)

KEY_PASS=securepass
STORE_PASS=securepass
CA_VALIDITY=365000
VALIDITY=36500
LOCAL_SERVER_NAMES=$(IFS=,; echo "${subject_alternate_names[*]}")

ca_keystore="server-ca-keystore.p12"
server_truststore="server-ca-truststore.p12"
server_keystore="server-keystore.p12"
ca_crt="server-ca.crt"
server_crt="server.crt"

cert_expire_days_gte() {
  echo "DEBUG: cert_expire_days_gte"
  set -e
  crt="$1"; shift
  days="$1"; shift
  seconds=$(($days * 86400))
  # return 0 if the certificate is valid for at least $days
  # return 1 otherwise
  if openssl x509 -checkend $seconds -noout -in "$crt"
  then
    echo "INFO: Certificate $crt is still valid for more than $days days"
    return 0
  else
    echo "WARN: Certificate $crt validity less than $days days"
    return 1
  fi
}

create_ca() {
  echo "INFO: create_ca"
  set -e
  # Create a key and self-signed certificate for the CA, to sign server certificate requests and use for trust:
  # ----------------------------------------------------------------------------------------------------
  keytool -storetype pkcs12 -keystore "$ca_keystore" \
    -storepass $STORE_PASS -keypass $KEY_PASS -alias server-ca -genkey -keyalg "RSA" -keysize 2048 \
    -dname "CN=ActiveMQ Artemis Server Certification Authority, OU=Artemis, O=ActiveMQ" \
    -validity $CA_VALIDITY -ext bc:c=ca:true
  # export the CA cert
  keytool -storetype pkcs12 -keystore "$ca_keystore" -storepass $STORE_PASS \
    -alias server-ca -exportcert -rfc > "$ca_crt"
}

create_server_truststore() {
  set -e
  # Create trust store with the server CA cert:
  # -------------------------------------------------------
  keytool -storetype pkcs12 -keystore "$server_truststore" \
    -storepass $STORE_PASS -keypass $KEY_PASS \
    -importcert -alias server-ca -file "$ca_crt" -noprompt
}

create_server_keypair() {
  echo "INFO: create_server_keypair"
  set -e
  # Create a key pair for the server
  keytool -storetype pkcs12 -keystore "$server_keystore" -storepass $STORE_PASS -keypass $KEY_PASS -alias server \
    -genkey -keyalg "RSA" -keysize 2048 \
    -dname "CN=ActiveMQ Artemis Server, OU=Artemis, O=ActiveMQ, L=AMQ, S=AMQ, C=AMQ" \
    -validity $VALIDITY -ext bc=ca:false \
    -ext eku=sA \
    -ext "san=$LOCAL_SERVER_NAMES"

  # load the  ca Cert into the broker keystore
  keytool -storetype pkcs12 -keystore "$server_keystore" -storepass $STORE_PASS -keypass $KEY_PASS \
    -importcert -alias server-ca -file "$ca_crt" -noprompt
}

create_server_signing_request() {
  echo "INFO: create_server_signing_request"
  set -e
  # create CSR (certificate signing request)
  keytool -storetype pkcs12 -keystore "$server_keystore" \
    -storepass $STORE_PASS -alias server -certreq -file server.csr
}

sign_with_ca() {
  echo "INFO: sign_with_ca"
  set -e
  # Sign the server certificate with the CA
  # ---------------------------------------
  keytool -storetype pkcs12 -keystore "$ca_keystore" -storepass $STORE_PASS -alias server-ca \
    -gencert -rfc -infile server.csr -outfile "$server_crt" -validity $VALIDITY \
    -ext bc=ca:false -ext eku=sA -ext "san=$LOCAL_SERVER_NAMES"
}

load_server_crt() {
  set -e
  echo "INFO: load_server_crt"
  # load the broker Cert into the broker keystore
  keytool -storetype pkcs12 -keystore "$server_keystore" -storepass $STORE_PASS -keypass $KEY_PASS \
    -importcert -alias server -file "$server_crt"
}

test -w "$ca_keystore" || {
  echo "INFO: Creating CA key pair"
  create_ca
  create_server_truststore
}

# Check if the server certificate will not expire in the next N days
if test -f "$server_crt" && cert_expire_days_gte "$server_crt" 30; then
  echo "INFO: using existing certificates"
else
  # Clean up existing files
  # -----------------------
  create_server_keypair
  create_server_signing_request
  sign_with_ca
  load_server_crt
fi
