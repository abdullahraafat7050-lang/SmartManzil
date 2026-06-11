#!/usr/bin/env python3
# ==================================================
# aklli_manzil - Seri Port Koprusu (Cift Yonlu)
# serial_reader.py'nin yerini alir.
# Arduino Serial <-> MQTT (okuma VE yazma)
#
# Okuma:  Arduino Serial JSON -> MQTT (sensor verisi)
# Yazma:  MQTT Flutter topics  -> Arduino Serial (aktuator kontrolu)
# ==================================================

import serial
import json
import time
import threading
import queue
import paho.mqtt.client as mqtt

from config import (
    SERIAL_PORT, SERIAL_BAUD, SERIAL_TIMEOUT,
    MQTT_BROKER, MQTT_PORT, MQTT_KEEPALIVE,
    MQTT_USERNAME, MQTT_PASSWORD,
    HOME_ID, SENSOR_PATHS, QOS_SENSOR, QOS_ACTUATOR,
    RECONNECT_DELAY, setup_logging
)

log = setup_logging("serial_bridge")

# Thread-safe Arduino yazma kuyrugu
_write_queue: queue.Queue = queue.Queue()

# Flutter oda adi -> Arduino relay adi eslemi
# Fiziksel baglantiyi yansitir:
#   living  -> RELAY_LIGHT_1_PIN (pin 22)
#   garden  -> RELAY_LIGHT_2_PIN (pin 23)  [bahce]
#   bedroom -> RELAY_LIGHT_3_PIN (pin 24)
#   fan     -> RELAY_FAN_PIN     (pin 25)
_ROOM_TO_RELAY = {
    "bedroom": "light1",
    "living":  "light2",
    "kitchen": "light3",
}

# Abone olunacak MQTT topic'leri (Flutter app'in gonderdigi)
_SUBSCRIBE_TOPICS = [
    "home/+/light",       # home/living/light, home/bedroom/light, ...
    "home/+/fan",         # fan kontrolu
    "home/garden/gate",   # kapi servo
    "home/window",        # pencere servo
]


# ── Payload yardimcisi ────────────────────────────────────────────────────────

def _extract_value(payload_str: str) -> str:
    """
    Flutter'dan gelen duz string ("1") veya
    JSON wrapper ({"value":1,"ts":...}) icerisindeki degeri cikar.
    """
    try:
        data = json.loads(payload_str)
        if isinstance(data, dict) and "value" in data:
            return str(data["value"])
    except (json.JSONDecodeError, TypeError):
        pass
    return payload_str.strip()


# ── MQTT -> Arduino donusumu ──────────────────────────────────────────────────

def _topic_to_serial_cmd(topic: str, payload_str: str) -> str | None:
    """
    Flutter MQTT topic + payload -> Arduino Serial JSON komutu.
    Bilinmeyen topic icin None dondurur.
    """
    value = _extract_value(payload_str)
    parts = topic.split("/")

    # home/{oda}/light  ->  {"path":"actuators/light1","value":1}
    if len(parts) == 3 and parts[2] == "light":
        room = parts[1]
        relay = _ROOM_TO_RELAY.get(room)
        if relay:
            int_val = 1 if value in ("1", "true", "True") else 0
            return json.dumps({"path": f"actuators/{relay}", "value": int_val})
        log.warning(f"Bilinmeyen oda: '{room}' — _ROOM_TO_RELAY'e ekleyin")
        return None

    # home/{oda}/fan  ->  {"path":"actuators/fan","value":1}
    if len(parts) == 3 and parts[2] == "fan":
        int_val = 1 if value in ("1", "true", "True") else 0
        return json.dumps({"path": "actuators/fan", "value": int_val})

    # home/garden/gate  ->  {"path":"actuators/gate","value":"open"}
    if topic == "home/garden/gate":
        action = "open" if value == "open" else "close"
        return json.dumps({"path": "actuators/gate", "value": action})

    # home/window  ->  {"path":"actuators/windows","value":"open"}
    if topic == "home/window":
        action = "open" if value in ("1", "true") else "close"
        return json.dumps({"path": "actuators/windows", "value": action})

    return None


# ── MQTT callback'leri ────────────────────────────────────────────────────────

def on_connect(client, userdata, flags, rc) -> None:
    if rc == 0:
        log.info("MQTT broker'a baglandi (Serial Bridge).")
        for topic in _SUBSCRIBE_TOPICS:
            client.subscribe(topic, qos=QOS_ACTUATOR)
            log.info(f"Abone olundu: {topic}")
    else:
        log.error(f"MQTT baglanti hatasi: {rc}")


def on_disconnect(client, userdata, rc) -> None:
    log.warning(f"MQTT baglantisi kesildi (rc={rc}).")


def on_message(client, userdata, msg) -> None:
    topic   = msg.topic
    payload = msg.payload.decode("utf-8", errors="ignore")

    cmd = _topic_to_serial_cmd(topic, payload)
    if cmd:
        _write_queue.put(cmd)
        log.info(f"Kuyruga alindi: {cmd}  [{topic} -> {payload}]")


# ── Arduino okuma dongusu (Serial → MQTT) ────────────────────────────────────

def _serial_read_loop(ser: serial.Serial, mqtt_client: mqtt.Client) -> None:
    log.info("Arduino okuma dongusu basladi.")
    while True:
        try:
            raw = ser.readline()
            if not raw:
                continue

            line = raw.decode("utf-8", errors="ignore").strip()
            if not line.startswith("{"):
                continue

            try:
                data = json.loads(line)
            except json.JSONDecodeError:
                log.warning(f"Gecersiz JSON: {line}")
                continue

            if "debug" in data:
                log.debug(f"[DEBUG] {data}")
                continue

            path  = data.get("path")
            value = data.get("value")
            if path is None or value is None:
                log.warning(f"Eksik alan: {data}")
                continue

            topic   = SENSOR_PATHS.get(path, f"home/{HOME_ID}/{path}")
            payload = json.dumps({"value": value, "ts": int(time.time())})
            mqtt_client.publish(topic, payload, qos=QOS_SENSOR, retain=True)
            log.info(f"Yayimlandi: {topic} -> {payload}")

        except serial.SerialException as e:
            log.error(f"Serial okuma hatasi: {e}")
            time.sleep(1)
        except Exception as e:
            log.error(f"Beklenmedik hata (okuma): {e}")
            time.sleep(0.5)


# ── Arduino yazma dongusu (MQTT → Serial) ────────────────────────────────────

def _serial_write_loop(ser: serial.Serial) -> None:
    log.info("Arduino yazma dongusu basladi.")
    while True:
        try:
            cmd  = _write_queue.get(timeout=1)
            line = cmd + "\n"
            ser.write(line.encode("utf-8"))
            ser.flush()
            log.info(f"Arduino'ya gonderildi: {cmd}")
        except queue.Empty:
            pass
        except serial.SerialException as e:
            log.error(f"Serial yazma hatasi: {e}")
            time.sleep(1)
        except Exception as e:
            log.error(f"Beklenmedik hata (yazma): {e}")


# ── Yardimci ──────────────────────────────────────────────────────────────────

def _open_serial(port: str, baud: int) -> serial.Serial:
    while True:
        try:
            ser = serial.Serial(port, baud, timeout=SERIAL_TIMEOUT)
            log.info(f"Serial port acildi: {port} @ {baud} baud")
            return ser
        except serial.SerialException as e:
            log.error(f"Serial port acilamadi: {e}. {RECONNECT_DELAY}s sonra...")
            time.sleep(RECONNECT_DELAY)


# ── Ana fonksiyon ─────────────────────────────────────────────────────────────

def main() -> None:
    client = mqtt.Client(client_id="manzil_serial_bridge", clean_session=True)
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
            log.error(f"MQTT baglantisi basarisiz: {e}. {RECONNECT_DELAY}s sonra...")
            time.sleep(RECONNECT_DELAY)

    client.loop_start()

    ser = _open_serial(SERIAL_PORT, SERIAL_BAUD)

    threading.Thread(
        target=_serial_read_loop,
        args=(ser, client),
        daemon=True,
        name="serial_read"
    ).start()

    threading.Thread(
        target=_serial_write_loop,
        args=(ser,),
        daemon=True,
        name="serial_write"
    ).start()

    log.info("Serial Bridge calisyor (cift yonlu: Arduino <-> MQTT)...")

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        log.info("Kullanici tarafindan durduruldu.")
    finally:
        client.loop_stop()
        client.disconnect()
        ser.close()
        log.info("Serial Bridge kapatildi.")


if __name__ == "__main__":
    main()
