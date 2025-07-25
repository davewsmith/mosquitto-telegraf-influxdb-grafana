# Notes

## Steps

  * MQTT
  * Telegraf / InfluxDB
  * Grafana

## MQTT

Wrote a simple compose.yml that uses `eclipse-mosquitto:latest` with default configuration.

    docker compose up

shows

```
mosquitto  | 1753469439: mosquitto version 2.0.22 starting
mosquitto  | 1753469439: Config loaded from /mosquitto/config/mosquitto.conf.
mosquitto  | 1753469439: Starting in local only mode. Connections will only be possible from clients running on this machine.
mosquitto  | 1753469439: Create a configuration file which defines a listener to allow remote access.
mosquitto  | 1753469439: For more details see https://mosquitto.org/documentation/authentication-methods/
```

I'll do that later.

    docker exec -it mosquitto mosquitto_sub -t '/#' -v

and

    docker exec -it mosquitto mosquitto_pub -t /test/topic -m 'hello there'

shows

    /test/topic hello there

as expected.
