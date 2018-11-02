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

CERT_HOSTNAME_WITHOUT_DOMAIN=$(echo "${CERT_HOSTNAME}" | cut -d"." -f1)

# https://security.stackexchange.com/questions/74345/provide-subjectaltname-to-openssl-directly-on-command-line

echo "Generating CA certificate cacert.pem"
openssl req -x509 -new -nodes -config openssl.cnf \
        -key /opt/healthcatalyst/testca/private/cakey.pem \
        -sha256 -days 3650 \
        -subj /CN=FabricCertificateAuthority/O=HealthCatalyst/ \
        -reqexts SAN -extensions SAN \
        -config <(cat openssl.cnf \
            <(printf "\n[SAN]\nsubjectAltName=DNS:${CERT_HOSTNAME},DNS:${CERT_HOSTNAME_WITHOUT_DOMAIN}")) \
        -out cacert.pem -outform PEM

echo "----- Checking the CA root certificate ----"
openssl x509 -in /opt/healthcatalyst/testca/cacert.pem -text -noout

echo "Converting cacert.pem to cacert.cer".
openssl x509 -in cacert.pem -out cacert.cer -outform DER

echo "creating cacert.p12"
openssl pkcs12 -nokeys -export -out cacert.p12 -in cacert.pem -inkey /opt/healthcatalyst/testca/private/cakey.pem -passout pass:$CertPassword

echo "contents of /opt/healthcatalyst/testca"
ls -al /opt/healthcatalyst/testca