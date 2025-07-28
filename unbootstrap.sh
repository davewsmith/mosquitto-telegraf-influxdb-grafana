#!/bin/sh
docker volume rm -f mqtt-grafana_mosquitto-data 
docker volume rm -f mqtt-grafana_influxdb-config mqtt-grafana_influxdb-storage
docker volume rm -f mqtt-grafana_grafana-storage 
