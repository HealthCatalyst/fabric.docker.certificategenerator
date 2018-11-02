docker stop fabric.docker.certificategenerator
docker rm fabric.docker.certificategenerator
docker build -t healthcatalyst/fabric.docker.certificategenerator .

Remove-Item -Force -Recurse C:\tmp\certificategenerator\*

Write-Host "Running"
docker run --rm -v /C/tmp/certificategenerator:/opt/certs/ `
    -e CERT_HOSTNAME=kubmaster.mshome.net `
    -e CERT_PASSWORD=mypassword `
    -e CLIENT_CERT_USER=fabricrabbitmquser `
    --name fabric.docker.certificategenerator `
    -t healthcatalyst/fabric.docker.certificategenerator
