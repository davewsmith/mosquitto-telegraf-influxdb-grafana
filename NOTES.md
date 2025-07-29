# Notes

## Steps

  * [done] MQTT
  * [done] Telegraf / InfluxDB
  * [done for now] Grafana
  * Script to inject sample data
  * Wire up wxbug to forward temperature reports

## Loose Ends

  * Go over the warnings logged when the stack starts
  * Manage secrets as secrets
  * Maybe a canned dashboard?

When it comes up, getting data from Tasmota converted to influx format is discussed in
https://community.influxdata.com/t/help-parsing-an-mqtt-message-from-a-tasmota-device/30485/6

Also https://www.blakecarpenter.dev/using-tasmota-smart-plugs-with-telegraf/

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

That was easy. Verified the data is arriving by using the InfluxDB UI (http://localhost:8086) and poking at the bucket.

## Grafana

I bet I need another token from InfluxDB... Yup. Added that to `bootstrap.sh`.

Easy part is done; Grafana starts up on http://localhost:3000/ (admin/admin)
then asks for a new password (but will reuse admin).

Now to sort out how to provision Grafana from volume binds. Maybe useful:

  * https://medium.com/swlh/easy-grafana-and-docker-compose-setup-d0f6f9fcec13 might be useful.
  * https://github.com/annea-ai/grafana-infrastructure/blob/master/grafana/Dockerfile provides some hints.

Done. Set up a datasource with the necessary InfluxDB token.
Added a health check on InfluxDB so that Grafana didn't throw up its hands in dispair when InfluxDB wasn't ready yet.

Secrets are still a bit of a mess. Gave Grafana admin creds (grafana/grafana) via
environment variables, which keeps it from requiring a password change on initial access.
(Chrome does complain about an insecure password, as it probably should.)

Now to decide whether to provision an initial dashboard, or write up instructions and call it good enough.

Oddly surprised that none of the examples I found when researching this used any sort of health check on InfluxDB,
but then none of them attempted to provision Grafana with an InfluxDB datasource.

## Interlude for cleanup and reflection

Just noticed a "Flux is currently in Beta" notice when looking at the Grafana datasource.
https://grafana.com/docs/grafana/latest/datasources/influxdb/configure-influxdb-data-source/
shows an example of provisioning an InfluxQL datasource.

Most of what I've seen has Telegraf marshalling to 'influx' format. But Tasmota like to send JSON,
so maybe an experiment is in order to see how JSON lands in InfluxDB.

https://www.influxdata.com/blog/import-json-data-influxdb-using-python-go-javascript-client-libraries/ shows
how to write directly to InfluxDB from Python. Maybe not of direct interest here, but it shows the
correct tranformation of a JSON structure into line format.

https://grafana.com/docs/grafana/latest/datasources/influxdb/query-editor/ shows a Flux example.

Gemini actually provides a reasonable summary of the InfluxDB hierarchy:

> In essence, data is organized into buckets, which contain measurements. Each point within a measurement is defined by its timestamp, a set of tags (for metadata and indexing), and a set of fields (for the actual data values).

Where tags and fields are key-value pairs.
