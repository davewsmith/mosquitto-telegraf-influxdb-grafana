# Notes

## Steps

  * [done] MQTT
  * [in progress] Telegraf / InfluxDB
  * Grafana

### Loose Ends

  * Go over the warnings logged when then stack starts
  * Manage secrets as secrets

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

to subscribe, and

    docker exec -it mosquitto mosquitto_pub -t /test/topic -m 'hello there'

to publish shows

    /test/topic hello there

as expected.

Added authentication for `mqtt/mqtt` and mounted `./mosquitto/conf` read-only to avoid
mosquitto chown'ing files and causing git to think there are metadata changes.
(See https://github.com/eclipse-mosquitto/mosquitto/issues/3284)

Now

    docker exec -it mosquitto mosquitto_sub -u mqtt -P mqtt -t '/#' -v

to subscribe, and

    docker exec -it mosquitto mosquitto_pub -u mqtt -P mqtt -t /test/topic -m 'new and improved'

to publish works as expected.

Pinned eclipse-mosquitto to 2.0.22 to avoid sudden breakage if they put teeth in their warning
about password file ownership.

## InfluxDB / Telegraf

The nuisance part here, at least with InfluxDB2, is that you need to run `influx` once to
create the token that Telgraf needs to talk to InfluxDB. There's a bunch of advice that's
implicitly based on the older v1 influx.

https://community.influxdata.com/t/ti-stack-with-docker-compose/19337/6 has an approach
that looks worth trying.

And, some futzing later, that seems to work.

After nuking existing volumes (`docker volume list ; docker volume rm ...`),

    ./bootstrap.sh

sets up InfluxDB, creates a user for Telegraf, and exfiltrates an token that goes into `.env`. Then

    docker compose up

brings up the stack.

Next up is to hook in Telegraf for realz.

With a `telegraf/telegraf.conf` of

```
[[inputs.mqtt_consumer]]
    servers = ["tcp://mqtt:1883"]
    username = "mqtt"
    password = "mqtt"
    topics = [
        "/#"
    ]
    topic_tag = "topic"
    
[[outputs.file]]
    files = ["stdout"]
    data_format = "influx"
```

```
docker exec -it mosquitto mosquitto_pub -u mqtt -P mqtt -t /test/topic -m 'mymeasure myvalue=42'
````

logs

```
telegraf   | mymeasure,host=5f5d76101b28,topic=/test/topic myvalue=42 1753556442926473549
```

That was simple. Now to hook it up to InfluxDB.

When it comes up, getting data from Tasmota converted to influx format is discussed in
https://community.influxdata.com/t/help-parsing-an-mqtt-message-from-a-tasmota-device/30485/6
