# aklli_manzil - Arduino Serial to MQTT Bridge (Dual Broker)
# Local Mosquitto + HiveMQ Cloud simultaneously

import serial
import json
import time
import threading
import ssl
import paho.mqtt.client as mqtt

# ── Arduino ───────────────────────────────────────────────────────────────────
ARDUINO_PORT = "/dev/ttyACM0"
BAUD_RATE    = 9600

# ── Local Mosquitto ───────────────────────────────────────────────────────────
LOCAL_HOST = "localhost"
LOCAL_PORT = 1883

# ── HiveMQ Cloud ─────────────────────────────────────────────────────────────
REMOTE_HOST = "09d4a42e19724bf7b2a3204bb9ee1bd2.s1.eu.hivemq.cloud"
REMOTE_PORT = 8883
REMOTE_USER = "akilli_menzil"
REMOTE_PASS = "a5eUB@njzud6s4C"

# ── Control topics to forward from MQTT → Arduino ────────────────────────────
CONTROL_TOPICS = [
    "home/garden/gate",
    "home/door/control",
    "home/+/light",
    "home/+/dimmer",
    "home/curtain/control",
]

arduino = None
arduino_lock = threading.Lock()


# ── Arduino helpers ───────────────────────────────────────────────────────────

def connect_arduino():
    global arduino
    ser = serial.Serial(ARDUINO_PORT, BAUD_RATE, timeout=1)
    time.sleep(2)
    arduino = ser
    print("[Arduino] Bağlantı başarılı.")
    return ser


def send_to_arduino(path, value):
    cmd = json.dumps({"path": path, "value": value})
    with arduino_lock:
        try:
            arduino.write((cmd + "\n").encode("utf-8"))
            print(f"[Arduino] Gönderildi -> {cmd}")
        except Exception as e:
            print(f"[Arduino] Yazma hatası: {e}")


# ── MQTT command handler (same for both brokers) ──────────────────────────────

def on_command(topic, payload_str):
    """Map an incoming MQTT control topic to an Arduino JSON command."""
    parts = topic.split("/")   # e.g. ['home', 'garden', 'gate']
    path  = "/".join(parts[1:])  # strip leading 'home/'
    send_to_arduino(path, payload_str)


# ── Local broker ──────────────────────────────────────────────────────────────

def _local_on_connect(client, _userdata, _flags, reason_code, _properties):
    if reason_code == 0:
        print("[Local] Bağlantı başarılı.")
        for topic in CONTROL_TOPICS:
            client.subscribe(topic, qos=1)
            print(f"[Local] Abone olundu: {topic}")
    else:
        print(f"[Local] Bağlantı hatası: {reason_code}")


def _local_on_message(_client, _userdata, msg):
    payload = msg.payload.decode("utf-8", errors="ignore").strip()
    print(f"[Local] Komut alındı <- {msg.topic}: {payload}")
    on_command(msg.topic, payload)


def _local_on_disconnect(_client, _userdata, _flags, reason_code, _properties):
    print(f"[Local] Bağlantı kesildi (kod={reason_code}). Otomatik yeniden bağlanılacak.")


def build_local_client():
    client = mqtt.Client(
        client_id="akilli_manzil_local",
        callback_api_version=mqtt.CallbackAPIVersion.VERSION2,
    )
    client.username_pw_set("smart_ev", "12345678")
    client.on_connect    = _local_on_connect
    client.on_message    = _local_on_message
    client.on_disconnect = _local_on_disconnect
    client.reconnect_delay_set(min_delay=5, max_delay=60)
    return client


# ── HiveMQ Cloud broker ───────────────────────────────────────────────────────

def _remote_on_connect(client, _userdata, _flags, reason_code, _properties):
    if reason_code == 0:
        print("[Remote] HiveMQ bağlantısı başarılı.")
        for topic in CONTROL_TOPICS:
            client.subscribe(topic, qos=1)
            print(f"[Remote] Abone olundu: {topic}")
    else:
        print(f"[Remote] Bağlantı hatası: {reason_code}")


def _remote_on_message(_client, _userdata, msg):
    payload = msg.payload.decode("utf-8", errors="ignore").strip()
    print(f"[Remote] Komut alındı <- {msg.topic}: {payload}")
    on_command(msg.topic, payload)


def _remote_on_disconnect(_client, _userdata, _flags, reason_code, _properties):
    print(f"[Remote] Bağlantı kesildi (kod={reason_code}). Otomatik yeniden bağlanılacak.")


def build_remote_client():
    client = mqtt.Client(
        client_id="akilli_manzil_remote",
        callback_api_version=mqtt.CallbackAPIVersion.VERSION2,
    )
    client.username_pw_set(REMOTE_USER, REMOTE_PASS)
    client.tls_set(cert_reqs=ssl.CERT_REQUIRED, tls_version=ssl.PROTOCOL_TLS)
    client.on_connect    = _remote_on_connect
    client.on_message    = _remote_on_message
    client.on_disconnect = _remote_on_disconnect
    client.reconnect_delay_set(min_delay=5, max_delay=60)
    return client


# ── Publish to both brokers ───────────────────────────────────────────────────

def publish_both(local_client, remote_client, path, value):
    topic = f"home/{path}"
    payload = json.dumps({
        "value": value,
        "source": "arduino_mega",
        "timestamp": int(time.time()),
    })

    for name, client in [("Local", local_client), ("Remote", remote_client)]:
        try:
            client.publish(topic, payload, qos=1, retain=False)
            print(f"[{name}] Gönderildi -> {topic}: {payload}")
        except Exception as e:
            print(f"[{name}] Yayın hatası: {e}")


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    # Arduino
    ser = connect_arduino()

    # Local broker
    local = build_local_client()
    try:
        local.connect(LOCAL_HOST, LOCAL_PORT, keepalive=60)
    except Exception as e:
        print(f"[Local] İlk bağlantı başarısız: {e}")
    local.loop_start()

    # Remote broker
    remote = build_remote_client()
    try:
        remote.connect(REMOTE_HOST, REMOTE_PORT, keepalive=60)
    except Exception as e:
        print(f"[Remote] İlk bağlantı başarısız: {e}")
    remote.loop_start()

    print("[Bridge] Hazır. Arduino dinleniyor...\n")

    while True:
        try:
            line = ser.readline().decode("utf-8", errors="ignore").strip()

            if not line:
                continue

            print("Arduino RAW:", line)

            try:
                data = json.loads(line)
            except json.JSONDecodeError:
                print("JSON olmayan mesaj atlandı:", line)
                continue

            if "path" in data and "value" in data:
                publish_both(local, remote, data["path"], data["value"])

            elif "debug" in data:
                print("Debug mesajı:", data)

            else:
                print("Bilinmeyen mesaj:", data)

        except KeyboardInterrupt:
            print("\n[Bridge] Durduruldu.")
            break

        except Exception as e:
            print("Hata:", e)
            time.sleep(1)

    ser.close()
    local.loop_stop()
    local.disconnect()
    remote.loop_stop()
    remote.disconnect()


if __name__ == "__main__":
    main()
