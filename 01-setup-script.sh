#!/bin/bash

export $(grep -v '^#' .env | xargs)

mkdir -p "$PWD/data/step-ca"
sudo chown -R 1000:1000 "$PWD/data/step-ca"
docker run --rm -it -v "$PWD/data/step-ca:/home/step" smallstep/step-ca step ca init


echo $CA_PASSWORD | sudo tee "$PWD/data/step-ca/secrets/password"
sudo chown -R 1000:1000 "$PWD/data/step-ca/secrets/password"


docker-compose up -d step-ca
docker-compose logs | grep "Root fingerprint" | grep -o '[^ ]\+$' >> "$PWD/data/step-ca/secrets/fingerprint"

docker-compose exec step-ca step ca provisioner add acme --type ACME
docker-compose restart

step ca bootstrap --ca-url https://localhost:9000 --install --fingerprint $(cat "$PWD/data/step-ca/secrets/fingerprint")

curl https://localhost:9000/health
