#!/bin/bash

set -eu

CertPassword="${CERT_PASSWORD:-}"

CertUser="${CLIENT_CERT_USERNAME:-$1}"

if [[ -z "${CERT_PASSWORD:-}" ]]; then
    echo "CERT_PASSWORD must be set"
    exit 1
fi

if [[ -z "${CertUser:-}" ]]; then
    echo "No username parameter passed to generateclientcert.sh"
    exit 1
fi

echo "----- Creating client certificate for user $CertUser with password $CertPassword --------"
cd /opt/healthcatalyst/client

echo "Generate a private RSA key key.pem."
openssl genrsa -out key.pem 2048

echo "Generate a certificate from our private key."
openssl req -new -key key.pem -out req.pem -outform PEM -subj /CN=$CertUser/O=HealthCatalyst/ -nodes

echo "Sign the certificate with our CA."
cd /opt/healthcatalyst/testca
openssl ca -config openssl.cnf -in /opt/healthcatalyst/client/req.pem -out /opt/healthcatalyst/client/cert.pem -notext -batch -extensions client_ca_extensions

echo "Create a key store that will contain our certificate."
cd /opt/healthcatalyst/client
openssl pkcs12 -export -out "$CertUser"_client_cert.p12 -in cert.pem -inkey key.pem -passout pass:$CertPassword

echo "Create a trust store that will contain the certificate of our CA."
# https://stackoverflow.com/questions/23935820/how-can-i-create-a-p12-file-without-a-private-key
openssl pkcs12 -nokeys -export -out fabric_ca_cert.p12 -in /opt/healthcatalyst/testca/cacert.pem -inkey /opt/healthcatalyst/testca/private/cakey.pem -passout pass:$CertPassword

echo "contents of /opt/healthcatalyst/client"
ls -al /opt/healthcatalyst/client