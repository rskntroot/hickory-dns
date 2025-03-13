# Hickory DNS

## Setup

``` bash
cp env.example .env
```

edit .env file as necessary

``` bash
docker compose up -d
```

## TODO

### entrypoint.sh

- check env for upstream servers
  - add upstream to config.toml

- check env for blocklists
  - curl blocklists to /opt/lists/
  - add blocklists to config.toml

- check for zone files in
  - load zones from default
  - add zones to config.toml

### docker

- docker image is too big
  - remove compiler pkgs after build

### dns over https

- havent decided how i want to implement cert mgmt yet
  - yeah letencrypt
  - but with touchless automation, how?
