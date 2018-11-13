docker stop fabric.docker.certificategenerator
docker rm fabric.docker.certificategenerator
docker build -t healthcatalyst/fabric.docker.certificategenerator .

Write-Host "Running"
docker run --rm `
    -e CERT_HOSTNAME=kubmaster.mshome.net `
    -e CERT_PASSWORD=mypassword `
    -e CLIENT_CERT_USER=fabricrabbitmquser `
    --name fabric.docker.certificategenerator `
    -t healthcatalyst/fabric.docker.certificategenerator
