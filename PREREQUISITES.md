<!-- TOC -->

- [Prerequisites](#prerequisites)
  - [Keep packages updated before install](#keep-packages-updated-before-install)
  - [Install Docker](#install-docker)
  - [Install Docker Compose manually](#install-docker-compose-manually)
  - [Update chmod](#update-chmod)
  - [Create account Docker hub (**JS only**)](#create-account-docker-hub-js-only)
  - [Install Git](#install-git)
  - [Install htpasswd part of apache2-utils](#install-htpasswd-part-of-apache2-utils)
  - [Install jq](#install-jq)
  - [Check that everything is ok](#check-that-everything-is-ok)

# Prerequisites

> If you have installed Caprover, it is necessary to uninstall it before installing Traefik. More info here [https://caprover.com/docs/troubleshooting.html#how-to-stop-and-remove-captain](https://caprover.com/docs/troubleshooting.html#how-to-stop-and-remove-captain).

## Keep packages updated before install

```bash
sudo apt update && sudo apt upgrade
```

## Install Docker

```bash
sudo apt install docker.io
```

## Install Docker Compose manually

https://docs.docker.com/compose/install/linux/#install-the-plugin-manually

```bash
DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
mkdir -p $DOCKER_CONFIG/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/v2.16.0/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose
```

## Update chmod

```bash
chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
sudo chmod 666 /var/run/docker.sock
```

## Create account Docker hub (**JS only**)

-   Create an account on Docker Hub [https://hub.docker.com/signup](https://hub.docker.com/signup)
-   Create a personal access token [https://hub.docker.com/settings/security](https://hub.docker.com/settings/security)

## Install Git

```bash
sudo apt install git
```

## Install htpasswd part of apache2-utils

Used to encrypt Traefik dashboard password access

```bash
sudo apt install apache2-utils
```

## Install jq

Used to parse json from github action environment variables to .env files.  
https://lindevs.com/install-jq-on-ubuntu

```bash
sudo apt install -y jq
```

## Check that everything is ok

```bash
docker -v
# Docker version 20.10.12, build 20.10.12-0ubuntu4

docker compose version
# Docker Compose version v2.16.0

git --version
# git version 2.34.1

htpasswd --help
# Usage: description

jq --version
# jq-1.6
```
