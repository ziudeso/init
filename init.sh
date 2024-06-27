#!/bin/bash

# Prompt the user for input
read -p "Do you want to install Docker? (y/n): " user_input
# Convert the input to lowercase to handle case insensitivity
user_input=$(echo "$user_input" | tr '[:upper:]' '[:lower:]')

# Check the user's input and execute a command conditionally
if [ "$user_input" == "yes" ]; then
    # Execute the command if the user inputs 'yes'
    echo "User input is 'yes'. Executing the command..."
    curl -fsSL get.docker.com | sudo bash
elif [ "$user_input" == "no" ]; then
    # If the user inputs 'no', do nothing or perform an alternative action
    echo "User input is 'no'. No command will be executed."
else
    # Handle invalid input
    echo "Invalid input. Please enter 'yes' or 'no'."
fi



mkdir -p /root/projects/traefik
cd /root/projects/traefik
docker network create traefik_default
touch acme.json && chmod 600 acme.json

yaml_content=$(cat <<EOF
version: "3.3"

services:

  traefik:
    image: traefik:latest
    container_name: traefik
    restart: always
    # command is same as editing the traefik.yml (reported for reference)
    command:
      - "--log.level=DEBUG"
      # - "--api.insecure=true"
      - "--providers.docker=true"
    ports:
      - '80:80'
      - '443:443'
      # - '8080:8080' # Dashboard
    networks:
      - traefik_default
      # - default
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - './traefik.yml:/traefik.yml'
      # NOTE: can skip if u don't need the traefik page
      # - './traefik_dynamic.yml:/traefik_dynamic.yml'
      - './acme.json:/acme.json'
    #TODO: finish config
    # labels:
    #   - "traefik.enable=true"
    #   - "traefik.http.routers.traefik.entrypoints=http"
    #   - "traefik.http.routers.traefik.rule=Host(`traefik.${PROJECT_BASE_URL}`)"
    #   - "traefik.http.middlewares.traefik-auth.basicauth.users=username:password"
    #   - "traefik.http.middlewares.traefik-https-redirect.redirectscheme.scheme=https"
    #   - "traefik.http.routers.traefik.middlewares=traefik-https-redirect"
    #   - "traefik.http.routers.traefik-secure.entrypoints=https"
    #   - "traefik.http.routers.traefik-secure.rule=Host(`traefik.${PROJECT_BASE_URL}`)"
    #   - "traefik.http.routers.traefik-secure.middlewares=traefik-auth"
    #   - "traefik.http.routers.traefik-secure.tls=true"
    #   - "traefik.http.routers.traefik-secure.tls.certresolver=http"
    #   - "traefik.http.routers.traefik-secure.service=api@internal"


volumes:
  portainer_data:

networks:
  traefik_default:
    external: true
EOF
)

# Specify the output file
output_file="/root/projects/traefik/docker-compose.yml"

# Write the content to the file
echo "$yaml_content" > $output_file

# Confirm the creation of the file
echo "Traefik Docker file '$output_file' created successfully."

yaml_content=$(cat <<EOF
entryPoints:
  web:
    address: ':80'
    http:
      redirections:
        entryPoint:
          to: websecure
          scheme: https
  websecure:
    address: ':443'

api:
  dashboard: true

certificatesResolvers:
  lets-encrypt:
    acme:
      # Comment for production, uncomment for staging
      # caServer: https://acme-staging-v02.api.letsencrypt.org/directory
      email: francesco.delog@gmail.com
      storage: acme.json
      tlsChallenge: {}
      
providers:
  docker:
    watch: true
    network: web
EOF
)

# Specify the output file
output_file="/root/projects/traefik/traefik.yml"

# Write the content to the file
echo "$yaml_content" > $output_file

# Confirm the creation of the file
echo "Traefik YAML file '$output_file' created successfully."