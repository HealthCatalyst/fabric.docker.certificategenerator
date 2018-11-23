docker stop fabric.docker.certificategenerator
docker rm fabric.docker.certificategenerator
docker build -t healthcatalyst/fabric.docker.certificategenerator .

Write-Host "Running"
docker run --rm `
    -e CERT_HOSTNAME=kubmaster.mshome.net `
    -e CERT_PASSWORD=mypassword `
    -e CLIENT_CERT_USER=fabricrabbitmquser `
    -e SLEEP_FOREVER="true" `
    --name fabric.docker.certificategenerator `
    -t healthcatalyst/fabric.docker.certificategenerator

# docker run -it `
#     -e CERT_HOSTNAME=kubmaster.mshome.net `
#     -e CERT_PASSWORD=mypassword `
#     -e CLIENT_CERT_USER=fabricrabbitmquser `
#     -e SAVE_KUBERNETES_SECRET2="true" `
#     -e SLEEP_FOREVER="true" `
#     --name fabric.docker.certificategenerator `
#     -t healthcatalyst/fabric.docker.certificategenerator
