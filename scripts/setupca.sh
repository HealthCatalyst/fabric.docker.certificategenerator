#!/bin/bash

set -eu

CertPassword="${CERT_PASSWORD:-}"

if [[ -z "${CERT_PASSWORD:-}" ]]; then
    echo "CERT_PASSWORD must be set"
    exit 1
fi

#
# Prepare the certificate authority (self-signed).
#
cd /opt/healthcatalyst/testca

echo "--- Creating a self-signed certificate that will serve a certificate authority (CA). ---"

echo "Creating private key cakey.pem"
sudo openssl genrsa -out /opt/healthcatalyst/testca/private/cakey.pem 2048

echo "Generating CA certificate cacert.pem"
openssl req -x509 -new -nodes -config openssl.cnf -key /opt/healthcatalyst/testca/private/cakey.pem -sha256 -days 3650 -out cacert.pem -outform PEM -subj /CN=FabricCertificateAuthority/O=HealthCatalyst/

echo "Converting cacert.pem to cacert.cer".
openssl x509 -in cacert.pem -out cacert.cer -outform DER

echo "creating cacert.p12"
openssl pkcs12 -nokeys -export -out cacert.p12 -in cacert.pem -inkey /opt/healthcatalyst/testca/private/cakey.pem -passout pass:$CertPassword

echo "contents of /opt/healthcatalyst/testca"
ls -al /opt/healthcatalyst/testca