# MySQL for railway.app

![Template Header](./template-header.svg)

Deploy MySQL 8 on Railway with the official Docker image.

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template)

## Environment

| Variable | Required | Description |
|----------|----------|-------------|
| `MYSQL_ROOT_PASSWORD` | Yes | Root password for MySQL |

## Optional

| Variable | Description |
|----------|-------------|
| `MYSQL_DATABASE` | Initial database name (default `app`) |

## Persistence

Mount a Railway volume at `/var/lib/mysql` for durable storage.

## Local

```bash
docker build -t railwayapp-mysql .
docker run --rm -e MYSQL_ROOT_PASSWORD=dev -p 3306:3306 railwayapp-mysql
```
