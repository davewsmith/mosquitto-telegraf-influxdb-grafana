#/bin/bash

# Bootstrap for wider use by creating a Telegraf user and
# getting it a token.

source .env

wait_for_influxdb() {
    echo -n "Waiting for InfluxDB "
    i=0
    until $(curl --output /dev/null --silent --head --fail http://localhost:8086); do
        echo -n "."
        sleep 1
        i=$((i + 1))
        if [[ $i -gt 60 ]] ; then
            echo " Timeout!"
            exit 1
        fi
    done
    echo ""
    return 0
}

docker compose up -d influxdb
wait_for_influxdb

echo "Getting $INFLUXDB_BUCKET bucket id"
bucket_id=$(docker exec -it influxdb influx bucket list | grep "$INFLUXDB_BUCKET" | awk '{print $1}')
echo "bucket_id = " $bucket_id
echo ""
echo "Creating users"
docker exec -it influxdb influx user create -n telegraf -p TODO-replace-me-with-an-env-var -o ${INFLUXDB_ORG}
docker exec -it influxdb influx user create -n grafana  -p TODO-replace-me-with-an-env-var -o ${INFLUXDB_ORG}
echo ""
echo "Generating auth tokens"
docker exec -it influxdb influx auth create -u telegraf -d telegraf_token -o ${INFLUXDB_ORG} --write-bucket $bucket_id
docker exec -it influxdb influx auth create -u grafana  -d grafana_token  -o ${INFLUXDB_ORG} --read-buckets
echo ""
echo "Extracting auth tokens"
telegraf_token=$(docker exec -it influxdb influx auth list | grep telegraf_token | awk '{print $3}')
grafana_token=$(docker exec -it influxdb influx auth list | grep grafana_token | awk '{print $3}')
echo ""
echo "Adding auth tokens to .env"
sed -i '/INFLUXDB_TELEGRAF_TOKEN/d' .env
echo INFLUXDB_TELEGRAF_TOKEN=$telegraf_token >> .env
sed -i '/INFLUXDB_GRAFANA_TOKEN/d' .env
echo INFLUXDB_GRAFANA_TOKEN=$grafana_token >> .env

docker compose down influxdb
