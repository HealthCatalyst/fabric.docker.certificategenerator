#!/bin/bash

set -eu

echo "running docker-entrypoint.sh"
echo "Version 2018.11.23.01"

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
export CERT_HOSTNAME_INTERNAL="internal.${CERT_HOSTNAME:-}"
export CERT_HOSTNAME_INTERNAL2="internal-${CERT_HOSTNAME:-}"

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
	namespace="${SECRET_NAMESPACE:-kube-system}"
	echo "--- Saving ssl certs as kubernetes secrets in namespace $namespace ---"
	cd /opt/certs

	cacert="${SECRETNAME_CA_CERT:-fabric-ca-cert}"
	# https://gist.github.com/fntlnz/cf14feb5a46b2eda428e000157447309
	echo "setting $cacert secret"
	kubectl delete secret $cacert -n $namespace --ignore-not-found=true
	kubectl create secret tls $cacert -n $namespace --key "testca/rootCA.key" --cert "testca/rootCA.crt"

	sslcert="${SECRETNAME_SSL_CERT:-fabric-ssl-cert}"
	echo "Setting $sslcert any old TLS certs"
	kubectl delete secret $sslcert -n $namespace --ignore-not-found=true

	echo "Storing TLS certs as kubernetes secret"
	kubectl create secret tls $sslcert -n $namespace --key "server/tls.key" --cert "server/tls.crt"

	clientcert="${SECRETNAME_CLIENT_CERT:-fabric-client-cert}"
	echo "setting $clientcert secret"
	kubectl delete secret $clientcert -n $namespace --ignore-not-found=true
	kubectl create secret tls $clientcert -n $namespace --key "client/client.key" --cert "client/client.crt"

	cacertdownload="${SECRETNAME_CA_CERT_DOWNLOADFILE:-fabric_ca_cert.p12}"
	echo "copying testca/rootCA.p12 to $cacertdownload"
	cp testca/rootCA.p12 $cacertdownload

	clientcertdownload="${SECRETNAME_CLIENT_CERT_DOWNLOADFILE:-fabricrabbitmquser_client_cert.p12}"
	echo "copying client/client.p12 to $clientcertdownload"
	cp client/client.p12 $clientcertdownload

	downloadcert="${SECRETNAME_DOWNLOAD_SSL_CERT:-fabric-ssl-download-cert}"
	echo "setting $downloadcert secret"
	kubectl delete secret $downloadcert -n $namespace --ignore-not-found=true
	kubectl create secret generic $downloadcert -n $namespace \
		--from-file="$cacertdownload" \
		--from-file="$clientcertdownload"

	echo "--- Finished creating kubernetes secrets ---"
fi

if [[ ! -z "${SLEEP_FOREVER:-}" ]]; then
    echo "sleeping forever via tail -f /dev/null"
    tail -f /dev/null
    exit 0
fi