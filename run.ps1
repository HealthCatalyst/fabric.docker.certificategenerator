docker stop fabric.docker.certificategenerator
docker rm fabric.docker.certificategenerator
docker build -t healthcatalyst/fabric.docker.certificategenerator .
docker volume create fabriccertificatestore
docker run -P --rm --mount src=fabriccertificatestore,dst=/opt/certs/ -e CERT_HOSTNAME=IamaHost -e CERT_PASSWORD=mypassword --name fabric.docker.certificategenerator -t healthcatalyst/fabric.docker.certificategenerator