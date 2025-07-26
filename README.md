# mqtt-grafana

A basic MQTT/Telegraf/InfluxDB/Grafana stack.

Nothing particularly novel here.
This replaces someone else's stack that I thought was getting overly complicated.
And it's an excuse to kick the moving parts around.

## Setup

Copy `env.template` to `.env` and edit it as you see fit

Provision a `telegraf` user and get it an InfluxDB access token.

    ./boostrap.sh

Then

    docker compose up

To bring the (partial) stack up.
At the moment, that's just mosquitto MQTT and InfluxDB,
without the connective tissue (Telegraf), or the flash
bit at the end (Grafana). Stay tuned.
