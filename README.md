# Hickory DNS

## Setup

``` bash
cp env.example .env
```

edit .env file as necessary

``` bash
docker compose up -d
```

## Notes

`entrypoint.sh` will skip `config.toml` creation if that file exists so you can edit it safely

`zones/example.org` is ingored during config gen

## Create Zone

set domain to your domain

``` bash
domain=rskio.com
```

``` bash
cd etc/zones
cp example.org ${domain}
```

you now have a persistent standard zone file for adding records

## TODO

### dns over https

- havent decided how i want to implement cert mgmt yet
  - yeah letencrypt
  - but with touchless automation, how?
