# mqtt-grafana

A basic MQTT/Telegraf/InfluxDB/Grafana stack.

Also **A WORK IN PROGRESS**, so use very much at your own risk.

Nothing particularly novel here.
This replaces someone else's stack that I thought was getting overly complicated.
And it's an excuse to kick the moving parts around.

## Setup

Copy `env.template` to `.env` and edit it as you see fit.

First run

    ./boostrap.sh

to set up InfluxDB and generate access tokens, then

    docker compose up

To bring the stack up.

> http://localhost:3000/

brings up Grafana (log in with grafana/grafana). A datasource is configured, but no dashboards yet.
