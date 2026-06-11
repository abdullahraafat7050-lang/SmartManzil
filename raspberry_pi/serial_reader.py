#!/usr/bin/env python3
# ==================================================
# aklli_manzil - Raspberry Pi Seri Port Okuyucu
# Arduino Mega'dan JSON verisi alir ve MQTT'ye gonderir
# ==================================================

import serial
import json
import time
import logging
import paho.mqtt.client as mqtt

from config import (
    SERIAL_PORT, SERIAL_BAUD, SERIAL_TIMEOUT,
    MQTT_BROKER, MQTT_PORT, MQTT_KEEPALIVE, MQTT_CLIENT_SERIAL,
    MQTT_USERNAME, MQTT_PASSWORD,
    HOME_ID, SENSOR_PATHS, ACTUATOR_TOPICS, QOS_SENSOR, QOS_ACTUATOR,
    RECONNECT_DELAY, LOG_LEVEL
)

# ---------------- LOGLAMA ----------------
log = logging.getLogger(__name__)

# Global seri port nesnesi (MQTT callback tarafindan yazmak icin)
_ser = None

# ---------------- MQTT CALLBACK'LER ----------------
def on_connect(client, userdata, flags, rc):
    if rc == 0:
        log.info("MQTT broker'a baglandi.")
        for topic in ACTUATOR_TOPICS.values():
            client.subscribe(topic, qos=QOS_ACTUATOR)
            log.info(f"Abone olundu (Aktuator): {topic}")

        wildcard = f"home/{HOME_ID}/actuators/#"
        client.subscribe(wildcard, qos=QOS_ACTUATOR)
        log.info(f"Abone olundu (Wildcard): {wildcard}")
    else:
        log.error(f"MQTT baglanti hatasi, kod: {rc}")

def on_disconnect(client, userdata, rc):
    log.warning(f"MQTT baglantisi kesildi (rc={rc}). Yeniden baglaniliyor...")

def on_message(client, userdata, msg):
    global _ser
    if _ser is None or not _ser.is_open:
        log.warning("Seri port acik degil, komut gonderilemedi.")
        return

    topic = msg.topic
    payload_str = msg.payload.decode("utf-8", errors="ignore")
    log.info(f"MQTT'den mesaj alindi: {topic} -> {payload_str}")

    try:
        data = json.loads(payload_str)
    except:
        data = payload_str

    commands_to_send = []

    parts = topic.split("/")
    if len(parts) >= 4 and parts[2] == "actuators":
        actuator = parts[3]

        # 1. Isik kontrolu
        if actuator == "lights":
            if isinstance(data, dict):
                for key in ["light1", "light2", "light3"]:
                    if key in data:
                        val = data[key]
                        if isinstance(val, dict):
                            val = val.get("value", 0)
                        int_val = 1 if (val == 1 or val is True or str(val).lower() in ["1", "true", "on"]) else 0
                        commands_to_send.append({"path": f"actuators/{key}", "value": int_val})

                if "path" in data and "value" in data:
                    sub = data["path"].split("/")[-1]
                    val = data["value"]
                    int_val = 1 if (val == 1 or val is True or str(val).lower() in ["1", "true", "on"]) else 0
                    commands_to_send.append({"path": f"actuators/{sub}", "value": int_val})

                if "action" in data and "rooms" in data:
                    action = data["action"]
                    rooms = data["rooms"]
                    int_val = 1 if action in ["on", "open"] else 0
                    room_to_light = {
                        "bedroom": "light1",
                        "living": "light2",
                        "living_room": "light2",
                        "kitchen": "light3"
                    }
                    for room in rooms:
                        light_key = room_to_light.get(room)
                        if light_key:
                            commands_to_send.append({"path": f"actuators/{light_key}", "value": int_val})
            else:
                try:
                    int_val = 1 if (data == 1 or data is True or str(data).lower() in ["1", "true", "on"]) else 0
                    for key in ["light1", "light2", "light3"]:
                        commands_to_send.append({"path": f"actuators/{key}", "value": int_val})
                except:
                    pass

        # 2. Diger aktuatorler (kapi, pencere, alarm, fan, servo)
        else:
            val = data
            if isinstance(data, dict):
                if "value" in data:
                    val = data["value"]
                elif "action" in data:
                    val = data["action"]
                elif "state" in data:
                    val = data["state"]

            # Pencere/kapi icin string degerler
            str_val = str(val).lower()
            if actuator in ("windows", "gate"):
                action = "open" if str_val in ["1", "true", "on", "open"] else "close"
                commands_to_send.append({"path": f"actuators/{actuator}", "value": action})
            else:
                # Fan ve diger relay'lar icin int deger
                int_val = 0
                if val == 1 or val is True or str_val in ["1", "true", "on", "open"]:
                    int_val = 1
                elif val == 0 or val is False or str_val in ["0", "false", "off", "close", "lock"]:
                    int_val = 0
                else:
                    try:
                        int_val = int(val)
                    except:
                        int_val = 0
                subpath = "/".join(parts[3:])
                commands_to_send.append({"path": f"actuators/{subpath}", "value": int_val})

    if not commands_to_send:
        commands_to_send.append({"topic": topic, "payload": data})

    for cmd in commands_to_send:
        command_str = json.dumps(cmd) + "\n"
        try:
            _ser.write(command_str.encode("utf-8"))
            log.info(f"Arduino'ya gonderildi: {command_str.strip()}")
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

    if "debug" in data:
        log.debug(f"[DEBUG] {data}")
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
