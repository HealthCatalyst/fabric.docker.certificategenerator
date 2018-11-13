#!/bin/bash

set -eu

echo "running docker-entrypoint.sh"
echo "Version 2018.11.13.01"

if [[ ! -d "/opt/certs" ]]; then
	echo "/opt/certs folder is not present.  Creating it..."
	mkdir -p /opt/certs
fi

mkdir -p /opt/certs/testca
mkdir -p /opt/certs/server
mkdir -p /opt/certs/client

echo "--- /opt/certs/testca/ ----"
ls /opt/certs/testca/
echo "---------------------------"

echo "--- /opt/certs/server/ ----"
ls /opt/certs/server/
echo "---------------------------"

echo "--- /opt/certs/client/ ----"
ls /opt/certs/client/
echo "---------------------------"

# make sure CertHostName and CertPassword are set
if [[ -z "${CERT_HOSTNAME:-}" ]]; then
	echo "CERT_HOSTNAME must be set"
	exit 1
fi

if [[ -z "${CERT_PASSWORD:-}" ]]; then
	echo "CERT_PASSWORD must be set"
	exit 1
fi

if [[ -z "${CLIENT_CERT_USER:-}" ]]; then
	echo "CERT_USER must be set"
	exit 1
fi

CertUser="${CLIENT_CERT_USER:-}"

export CERT_HOSTNAME_WITHOUT_DOMAIN=$(echo "${CERT_HOSTNAME}" | cut -d"." -f1)

if [[ ! -f "/opt/certs/testca/rootCA.p12" ]]
then
	echo "no certificates found so regenerating them"

	/bin/bash /opt/healthcatalyst/setupca.sh \
		&& /bin/bash /opt/healthcatalyst/generateservercert.sh \
		&& /bin/bash /opt/healthcatalyst/generateclientcert.sh $CertUser \
		&& echo "copying to /opt/certs" \
		&& mkdir -p /opt/certs/testca \
		&& cp /opt/healthcatalyst/testca/cacert.pem /opt/certs/testca/rootCA.crt \
		&& cp /opt/healthcatalyst/testca/cacert.p12 /opt/certs/testca/rootCA.p12 \
		&& cp /opt/healthcatalyst/testca/private/cakey.pem /opt/certs/testca/rootCA.key \
		&& mkdir -p /opt/certs/server \
		&& cp /opt/healthcatalyst/server/cert.pem /opt/certs/server/tls.crt \
		&& cp /opt/healthcatalyst/server/key.pem /opt/certs/server/tls.key \
		&& cp /opt/healthcatalyst/server/ca-chain.pem /opt/certs/server/tlschain.crt \
		&& cp /opt/healthcatalyst/server/keycert.p12 /opt/certs/server/tls.p12 \
		&& mkdir -p /opt/certs/client \
		&& cp /opt/healthcatalyst/client/fabricrabbitmquser_client_cert.p12 /opt/certs/client/client.p12 \
		&& cp /opt/healthcatalyst/client/key.pem /opt/certs/client/client.key \
		&& cp /opt/healthcatalyst/client/cert.pem /opt/certs/client/client.crt
else
	echo "certificates already exist so we're not regenerating them"
fi

if [[ ! -z "${SAVE_KUBERNETES_SECRET:-}" ]]; then
	echo "Saving kubernetes secret"
fi