import random
import time

import paho.mqtt.client as mqtt


def on_publish(client, userdata, mid, reason_code, properties):
    try:
        userdata.remove(mid)
    except KeyError as ex:
        print(f"{ex!r}")


mqtt_client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2, "inject")
mqtt_client.username = "mqtt"
mqtt_client.password = "mqtt"

mqtt_client.on_publish = on_publish

unacked_mids = set()
mqtt_client.user_data_set(unacked_mids)

mqtt_client.connect("localhost")
mqtt_client.loop_start()

for _ in range(10):
    x = random.randint(1,10)
    y = random.randint(1,10)
    msg = f"sample,somekey=somevalue X={x},Y={y}"
    pub = mqtt_client.publish("test/topic", msg, qos=1)
    unacked_mids.add(pub.mid)
    pub.wait_for_publish()
    assert len(unacked_mids) == 0
    time.sleep(1)


while len(unacked_mids):
    time.sleep(0.5)

mqtt_client.disconnect()
mqtt_client.loop_stop()

