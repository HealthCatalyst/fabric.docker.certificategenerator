#!/bin/bash

set -eu

# https://stackoverflow.com/questions/39296472/shell-script-how-to-check-if-an-environment-variable-exists-and-get-its-value
if [[ ! -z "${CERT_PASSWORD_FILE:-}" ]]
then
    echo "CERT_PASSWORD_FILE is set so reading from $CERT_PASSWORD_FILE"
    CERT_PASSWORD=$(cat $CERT_PASSWORD_FILE)
fi

CertPassword="${CERT_PASSWORD:-}"

if [[ ! -z "${CERT_HOSTNAME_FILE:-}" ]]
then
    echo "CERT_HOSTNAME_FILE is set so reading from $CERT_HOSTNAME_FILE"
    CERT_HOSTNAME=$(cat $CERT_HOSTNAME_FILE)
fi
MyHostName="${CERT_HOSTNAME:-}"

echo "------ Creating server certificate --------"
cd /opt/healthcatalyst/server

echo "Creating private key key.pem"
openssl genrsa -out key.pem 2048

echo "Generate a certificate req.pem from our private key."
openssl req -new -key key.pem -out req.pem -outform PEM -subj /CN=$MyHostName/O=HealthCatalyst/ -nodes

echo "Sign the certificate with our CA."
cd /opt/healthcatalyst/testca
openssl ca -config openssl.cnf -in /opt/healthcatalyst/server/req.pem -out /opt/healthcatalyst/server/cert.pem -notext -batch -extensions server_ca_extensions

echo "Create a key store that will contain our certificate. keycert.p12"
cd /opt/healthcatalyst/server
openssl pkcs12 -export -out keycert.p12 -in cert.pem -inkey key.pem -passout pass:$CertPassword

echo "contents of /opt/healthcatalyst/server"
ls -al /opt/healthcatalyst/server