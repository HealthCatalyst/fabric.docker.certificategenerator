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

#
# Prepare the certificate authority (self-signed).
#
cd /opt/healthcatalyst/testca

#
# Prepare the server's stuff.
#
cd /opt/healthcatalyst/server

# Generate a private RSA key.
openssl genrsa -out key.pem 2048

# Generate a certificate from our private key.
openssl req -new -key key.pem -out req.pem -outform PEM -subj /CN=$MyHostName/O=HealthCatalyst/ -nodes

# Sign the certificate with our CA.
cd /opt/healthcatalyst/testca
openssl ca -config openssl.cnf -in /opt/healthcatalyst/server/req.pem -out /opt/healthcatalyst/server/cert.pem -notext -batch -extensions server_ca_extensions

# Create a key store that will contain our certificate.
cd /opt/healthcatalyst/server
openssl pkcs12 -export -out keycert.p12 -in cert.pem -inkey key.pem -passout pass:$CertPassword

