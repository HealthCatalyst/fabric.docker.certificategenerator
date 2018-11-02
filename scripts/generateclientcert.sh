#!/bin/bash

set -eu

# https://stackoverflow.com/questions/39296472/shell-script-how-to-check-if-an-environment-variable-exists-and-get-its-value
if [[ ! -z "${CERT_PASSWORD_FILE:-}" ]]
then
    echo "CERT_PASSWORD_FILE is set so reading from $CERT_PASSWORD_FILE"
    CERT_PASSWORD=$(cat $CERT_PASSWORD_FILE)
fi
CertPassword="${CERT_PASSWORD:-}"

CertUser="${CLIENT_CERT_USERNAME:-$1}"

if [[ -z "${CERT_PASSWORD:-}" ]]; then
    echo "CERT_PASSWORD must be set"
    exit 1
fi

if [[ -z "${CertUser:-}" ]]; then
    echo "No username parameter passed fo generateclientcert.sh"
    exit 1
fi

#
# Prepare the client's stuff.
#
cd /opt/healthcatalyst/client

# Generate a private RSA key.
openssl genrsa -out key.pem 2048

# Generate a certificate from our private key.
openssl req -new -key key.pem -out req.pem -outform PEM -subj /CN=$CertUser/O=HealthCatalyst/ -nodes

# Sign the certificate with our CA.
cd /opt/healthcatalyst/testca
openssl ca -config openssl.cnf -in /opt/healthcatalyst/client/req.pem -out /opt/healthcatalyst/client/cert.pem -notext -batch -extensions client_ca_extensions

# Create a key store that will contain our certificate.
cd /opt/healthcatalyst/client
openssl pkcs12 -export -out "$CertUser"_client_cert.p12 -in cert.pem -inkey key.pem -passout pass:$CertPassword

# Create a trust store that will contain the certificate of our CA.
# https://stackoverflow.com/questions/23935820/how-can-i-create-a-p12-file-without-a-private-key
openssl pkcs12 -nokeys -export -out fabric_ca_cert.p12 -in /opt/healthcatalyst/testca/cacert.pem -inkey /opt/healthcatalyst/testca/private/cakey.pem -passout pass:$CertPassword
