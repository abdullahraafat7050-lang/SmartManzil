#!/usr/bin/env python3
# ==================================================
# aklli_manzil - Raspberry Pi Seri Port Okuyucu
# Arduino Mega'dan JSON verisi alir ve MQTT'ye gonderir
#
# Duzeltmeler:
#   - Loop-back korumasi duzeltildi: ts alani yoksayilir
#   - Lights komutu duzeltildi
#   - main() tekrar cagri kaldirildi
# ==================================================

import serial
import json
import time
import threading
import logging
import paho.mqtt.client as mqtt

from config import (
    SERIAL_PORT, SERIAL_BAUD, SERIAL_TIMEOUT,
    MQTT_BROKER, MQTT_PORT, MQTT_KEEPALIVE, MQTT_CLIENT_SERIAL,
    MQTT_USERNAME, MQTT_PASSWORD,
    HOME_ID, SENSOR_PATHS, ACTUATOR_TOPICS, QOS_SENSOR, QOS_ACTUATOR,
    RECONNECT_DELAY
)

# ---------------- LOGLAMA ----------------
log = logging.getLogger(__name__)

_ser = None

# ── Loop-back korumasi ────────────────────────────────────────────────────────
# Kaydedilen komutlar: (path_son, value) tuple olarak saklanir
# ts alani yoksayilir — her mesajda farklidir
_sent_lock: threading.Lock = threading.Lock()
_sent_commands: set = set()

def _normalize(payload_str: str):
    """
    Payload'dan (path son kismi, value) tuple'i cikar.
    ts alani yoksayilir.
    Ornek: {"path":"actuators/alarm","value":0} -> ("alarm", 0)
    Ornek: {"ts":123,"value":0} -> None (path yok, sensor mesaji)
    """
    try:
        data = json.loads(payload_str)
        path  = data.get("path", "")
        value = data.get("value")
        if path and value is not None:
            return (path.split("/")[-1], value)
    except Exception:
        pass
    return None

def _remember_sent(path: str, value) -> None:
    key = (path.split("/")[-1], value)
    with _sent_lock:
        _sent_commands.add(key)
    threading.Timer(3.0, lambda: _forget_sent(key)).start()

def _forget_sent(key) -> None:
    with _sent_lock:
        _sent_commands.discard(key)

def _was_sent_by_us(payload_str: str) -> bool:
    key = _normalize(payload_str)
    if key is None:
        return False
    with _sent_lock:
        return key in _sent_commands

# ── Flutter direkt light topic esleme ────────────────────────────────────────
FLUTTER_LIGHT_TOPICS = {
    "home/bedroom/light": "actuators/light1",
    "home/living/light":  "actuators/light2",
    "home/kitchen/light": "actuators/light3",
}

# ---------------- MQTT CALLBACK'LER ----------------
def on_connect(client, userdata, flags, rc):
    if rc == 0:
        log.info("MQTT broker'a baglandi.")
        for topic in ACTUATOR_TOPICS.values():
            client.subscribe(topic, qos=QOS_ACTUATOR)
            log.info(f"Abone olundu (Aktuator): {topic}")
        client.subscribe("home/+/light", qos=QOS_ACTUATOR)
        log.info("Abone olundu (Flutter lights): home/+/light")
    else:
        log.error(f"MQTT baglanti hatasi, kod: {rc}")

def on_disconnect(client, userdata, rc):
    log.warning(f"MQTT baglantisi kesildi (rc={rc}).")

def on_message(client, userdata, msg):
    global _ser
    if _ser is None or not _ser.is_open:
        log.warning("Seri port acik degil, komut gonderilemedi.")
        return

    topic       = msg.topic
    payload_str = msg.payload.decode("utf-8", errors="ignore")

    # ── Loop-back korumasi: ts'siz karsilastirma ──
    if _was_sent_by_us(payload_str):
        log.debug(f"Loop-back mesaji yoksayildi: {topic}")
        return

    log.info(f"MQTT'den mesaj alindi: {topic} -> {payload_str}")

    try:
        data = json.loads(payload_str)
    except Exception:
        data = payload_str

    # ── تخطي Arduino feedback (إذا لم تكن "path" موجودة، فهي feedback) ──
    if isinstance(data, dict) and "path" not in data:
        log.debug(f"Arduino feedback yoksayildi: {payload_str}")
        return

    commands_to_send = []

    # ── 1. Flutter direkt light topic'leri ──
    if topic in FLUTTER_LIGHT_TOPICS:
        arduino_path = FLUTTER_LIGHT_TOPICS[topic]
        raw_val = data if not isinstance(data, dict) else data.get("value", data.get("action", 0))
        int_val = 1 if str(raw_val).lower() in ["1", "true", "on"] else 0
        commands_to_send.append({"path": arduino_path, "value": int_val})

    # ── 2. home/{HOME_ID}/actuators/... topic'leri ──
    else:
        parts = topic.split("/")
        if len(parts) >= 4 and parts[2] == "actuators":
            actuator = parts[3]

            if actuator == "lights":
                if isinstance(data, dict):
                    for key in ["light1", "light2", "light3"]:
                        if key in data:
                            val = data[key]
                            if isinstance(val, dict):
                                val = val.get("value", 0)
                            int_val = 1 if str(val).lower() in ["1", "true", "on"] else 0
                            commands_to_send.append({"path": f"actuators/{key}", "value": int_val})

                    if "path" in data and "value" in data:
                        commands_to_send.append({
                            "path":  data["path"],
                            "value": 1 if str(data["value"]).lower() in ["1", "true", "on"] else 0
                        })

                    if "action" in data and "rooms" in data:
                        int_val = 1 if data["action"] in ["on", "open"] else 0
                        room_map = {
                            "bedroom":     "light1",
                            "living":      "light2",
                            "living_room": "light2",
                            "kitchen":     "light3",
                        }
                        for room in data["rooms"]:
                            lk = room_map.get(room)
                            if lk:
                                commands_to_send.append({"path": f"actuators/{lk}", "value": int_val})

            else:
                val = data
                if isinstance(data, dict):
                    val = data.get("value", data.get("action", data.get("state", 0)))

                # معالجة خاصة لـ windows, gate, doors (يجب string)
                if actuator in ("windows", "gate", "doors"):
                    str_val = str(val).lower()
                    action = "open" if str_val in ["1", "true", "on", "open"] else "close"
                    commands_to_send.append({"path": f"actuators/{actuator}", "value": action})
                else:
                    # Fan وأجهزة relay أخرى تحتاج int
                    int_val = 0
                    if str(val).lower() in ["1", "true", "on", "open"]:
                        int_val = 1
                    elif str(val).lower() in ["0", "false", "off", "close", "lock"]:
                        int_val = 0
                    else:
                        try:
                            int_val = int(val)
                        except Exception:
                            int_val = 0

                    subpath = "/".join(parts[3:])
                    commands_to_send.append({"path": f"actuators/{subpath}", "value": int_val})

    if not commands_to_send:
        log.warning(f"Komut olusturulamadi, atlanıyor: {topic} -> {payload_str}")
        return

    # Arduino'ya gonder
    for cmd in commands_to_send:
        command_str = json.dumps(cmd)
        # ✅ path ve value tuple olarak kaydet (ts yoksayilir)
        _remember_sent(cmd["path"], cmd["value"])
        try:
            _ser.write((command_str + "\n").encode("utf-8"))
            log.info(f"Arduino'ya gonderildi: {command_str}")
        except Exception as e:
            log.error(f"Arduino'ya yazma hatasi: {e}")


# ---------------- ANA ISLEVLER ----------------
def build_mqtt_topic(path: str) -> str:
    return SENSOR_PATHS.get(path, f"home/{HOME_ID}/{path}")


def process_line(line: str, mqtt_client: mqtt.Client) -> None:
    line = line.strip()
    if not line.startswith("{"):
        return

    try:
        data = json.loads(line)
    except json.JSONDecodeError:
        log.warning(f"Gecersiz JSON: {line}")
        return

    if "debug" in data or "ack" in data:
        log.debug(f"[SKIP] {data}")
        return

    path  = data.get("path")
    value = data.get("value")

    if path is None or value is None:
        log.warning(f"Eksik alan: {data}")
        return

    topic   = build_mqtt_topic(path)
    payload = json.dumps({"value": value, "ts": int(time.time())})

    result = mqtt_client.publish(topic, payload, qos=QOS_SENSOR, retain=True)

    if result.rc == mqtt.MQTT_ERR_SUCCESS:
        log.info(f"Yayimlandi  {topic} -> {payload}")
    else:
        log.error(f"Yayimlama hatasi: {result.rc} | topic={topic}")


def open_serial(port: str, baud: int) -> serial.Serial:
    while True:
        try:
            ser = serial.Serial(port, baud, timeout=SERIAL_TIMEOUT)
            log.info(f"Seri port acildi: {port} @ {baud} baud")
            return ser
        except serial.SerialException as e:
            log.error(f"Seri port acilamadi: {e}. {RECONNECT_DELAY}s sonra tekrar...")
            time.sleep(RECONNECT_DELAY)


def main():
    global _ser

    client = mqtt.Client(client_id=MQTT_CLIENT_SERIAL, clean_session=True)
    if MQTT_USERNAME and MQTT_PASSWORD:
        client.username_pw_set(MQTT_USERNAME, MQTT_PASSWORD)
    client.on_connect    = on_connect
    client.on_disconnect = on_disconnect
    client.on_message    = on_message

    while True:
        try:
            client.connect(MQTT_BROKER, MQTT_PORT, keepalive=MQTT_KEEPALIVE)
            break
        except Exception as e:
            log.error(f"MQTT baglantisi basarisiz: {e}. {RECONNECT_DELAY}s sonra tekrar...")
            time.sleep(RECONNECT_DELAY)

    client.loop_start()
    _ser = open_serial(SERIAL_PORT, SERIAL_BAUD)
    log.info("Seri okuma dongusu basladi...")

    while True:
        try:
            raw = _ser.readline()
            if raw:
                line = raw.decode("utf-8", errors="ignore")
                process_line(line, client)

        except serial.SerialException as e:
            log.error(f"Seri hata: {e}. Yeniden baglaniliyor...")
            _ser.close()
            time.sleep(RECONNECT_DELAY)
            _ser = open_serial(SERIAL_PORT, SERIAL_BAUD)

        except KeyboardInterrupt:
            log.info("Kullanici tarafindan durduruldu.")
            break

        except Exception as e:
            log.error(f"Beklenmedik hata: {e}")
            time.sleep(1)

    if _ser:
        _ser.close()
    client.loop_stop()
    client.disconnect()
    log.info("Program kapatildi.")


if __name__ == "__main__":
    main()