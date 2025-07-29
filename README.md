# mosquitto-telegraf-influxdb-grafana

A basic MQTT (Mosquitto) to TIG (Telegraf/InfluxDB/Grafana) stack.

Also **A WORK IN PROGRESS**, so use very much at your own risk.

Nothing particularly novel here.
This replaces someone else's stack that I thought was getting overly complicated.
And it's an excuse to kick the moving parts around.

## Setup for development

Copy `env.template` to `.env` and edit it as you see fit.

First run

    ./boostrap.sh

to set up InfluxDB and generate access tokens, then

    docker compose up

To bring the stack up. http://localhost:3000/ will access Grafana (creds are grafana/grafana).
A datasource is configured, but no dashboards yet.

To clean up after experiments, or after changing `.env` significantly,

    docker compose down
    docker system prune
    ./unbootstrap.sh  # to delete volumes

To inject some simple dsample data into the mix

    cd injector
    python3 -m venv venv
    . venv/bin/activate
    pip install -r requirements.txt
    python inject.py
