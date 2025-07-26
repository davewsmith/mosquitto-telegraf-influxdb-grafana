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
echo "creating user"
docker exec -it influxdb influx user create -n telegraf -p TODO-replace-me-with-an-env-var -o home
echo ""
echo "auth for user"
docker exec -it influxdb influx auth create -u telegraf -d telegraf_token -o home --write-bucket $bucket_id
echo ""
echo "extrating token"
token=$(docker exec -it influxdb influx auth list | grep telegraf_token | awk '{print $3}')
echo ""
sed -i '/INFLUXDB_TELEGRAF_TOKEN/d' .env
echo INFLUXDB_TELEGRAF_TOKEN=$token >> .env

docker compose down influxdb
