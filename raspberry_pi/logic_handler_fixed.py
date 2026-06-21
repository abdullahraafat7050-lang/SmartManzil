#!/usr/bin/env python3
# ==================================================
# aklli_manzil - Otomasyon Mantigi Isleyici (FIXED)
# Raspberry Pi uzerinde calisir
# ==================================================

import json
import time
import logging
import threading
import paho.mqtt.client as mqtt

from config import (
    MQTT_BROKER, MQTT_PORT, MQTT_KEEPALIVE, MQTT_CLIENT_LOGIC,
    MQTT_USERNAME, MQTT_PASSWORD,
    HOME_ID, SENSOR_PATHS, ACTUATOR_TOPICS,
    QOS_ACTUATOR, EVENT_COOLDOWN, SLEEP_MODE_DELAY_MINUTES,
    RECONNECT_DELAY, setup_logging
)

log = setup_logging("logic_handler")

state = {
    "rain":        0,
    "flame":       0,
    "motion":      0,
    "gas":         0,
    "gas_analog":  0,
    "temperature": 0.0,
    "humidity":    0.0,
}

last_event_time = {k: 0.0 for k in EVENT_COOLDOWN}
sleep_mode_timer: threading.Timer = None
_mqtt_client: mqtt.Client = None


def publish_actuator(key: str, command: dict) -> None:
    """Aktuator topic'ine JSON komutu gonder."""
    if key not in ACTUATOR_TOPICS:
        log.warning(f"Bilinmeyen aktuator anahtari: {key}")
        return

    topic   = ACTUATOR_TOPICS[key]
    payload = json.dumps(command)
    result  = _mqtt_client.publish(topic, payload, qos=QOS_ACTUATOR, retain=True)

    if result.rc == mqtt.MQTT_ERR_SUCCESS:
        log.info(f"Aktuator komutu → {topic} : {payload}")
    else:
        log.error(f"Aktuator yayimlama hatasi: {result.rc}")


def cooldown_ok(event_key: str) -> bool:
    """Bu olay icin bekleme suresi dolmus mu?"""
    elapsed = time.time() - last_event_time.get(event_key, 0)
    return elapsed >= EVENT_COOLDOWN.get(event_key, 0)


def mark_event(event_key: str) -> None:
    """Olayı zamanla isaretle (cooldown baslat)."""
    last_event_time[event_key] = time.time()


def handle_gas(value: int) -> None:
    """Gaz algilandi: Pencereler ac + Kapi ac + Aspirator + Alarm"""
    if value == 1 and cooldown_ok("gas"):
        log.warning("⚠️  GAZ ALGILANDI — Otomasyon baslatiyor!")
        mark_event("gas")

        publish_actuator("windows", {"action": "open",  "source": "gas_alert"})
        publish_actuator("gate",    {"action": "open",  "source": "gas_alert"})
        publish_actuator("fan",     {"action": "on",    "source": "gas_alert"})
        publish_actuator("alarm",   {"action": "on",    "source": "gas_alert"})

    elif value == 0:
        publish_actuator("fan",   {"action": "off", "source": "gas_clear"})
        publish_actuator("alarm", {"action": "off", "source": "gas_clear"})
        log.info("✅  Gaz tehlikesi gecti.")


def handle_flame(value: int) -> None:
    """Yangin algilandi: Tum kapilari ac + Pencereler + Alarm"""
    if value == 1 and cooldown_ok("flame"):
        log.warning("🔥  YANGIN ALGILANDI — Tum kaciş yollari aciliyor!")
        mark_event("flame")

        publish_actuator("doors",   {"action": "open", "source": "fire_alert"})
        publish_actuator("gate",    {"action": "open", "source": "fire_alert"})
        publish_actuator("windows", {"action": "open", "source": "fire_alert"})
        publish_actuator("alarm",   {"action": "on",   "source": "fire_alert"})

    elif value == 0:
        publish_actuator("alarm", {"action": "off", "source": "fire_clear"})
        log.info("✅  Yangin tehlikesi gecti.")


def handle_rain(value: int) -> None:
    """Yagmur algilandi: Pencereleri kapat"""
    if value == 1 and cooldown_ok("rain"):
        log.info("🌧️  YAGMUR ALGILANDI — Pencereler kapatiliyor.")
        mark_event("rain")

        publish_actuator("windows", {"action": "close", "source": "rain_alert"})

    elif value == 0:
        log.info("✅  Yagmur durdu.")


def handle_motion(value: int) -> None:
    """PIR hareketi algiladi: Her seyi kilitle"""
    if value == 1 and cooldown_ok("motion"):
        log.warning("🚨  IZINSIZ GIRIS — Her sey kilitleniyor!")
        mark_event("motion")

        publish_actuator("doors",   {"action": "lock",  "source": "intruder_alert"})
        publish_actuator("windows", {"action": "lock",  "source": "intruder_alert"})
        publish_actuator("gate",    {"action": "lock",  "source": "intruder_alert"})


def start_sleep_mode_timer() -> None:
    """Uyku modu aktivasyonunda zamanlayici baslat."""
    global sleep_mode_timer

    if sleep_mode_timer is not None:
        sleep_mode_timer.cancel()

    delay = SLEEP_MODE_DELAY_MINUTES * 60
    sleep_mode_timer = threading.Timer(delay, execute_sleep_mode)
    sleep_mode_timer.daemon = True
    sleep_mode_timer.start()
    log.info(f"😴  Uyku modu {SLEEP_MODE_DELAY_MINUTES} dakika sonra aktif olacak.")


def execute_sleep_mode() -> None:
    """Esansiyel olmayan isiklari kapat."""
    log.info("😴  Uyku modu — Esansiyel olmayan isiklar kapatiliyor.")
    publish_actuator("lights", {
        "action":  "off",
        "rooms":   ["living_room", "kitchen", "garden"],
        "source":  "sleep_mode"
    })


def on_connect(client, userdata, flags, rc):
    if rc == 0:
        log.info("MQTT broker'a baglandi (Logic Handler).")
        for topic in SENSOR_PATHS.values():
            client.subscribe(topic, qos=1)
            log.info(f"Abone olundu: {topic}")

        client.subscribe(f"home/{HOME_ID}/mode/sleep", qos=1)
    else:
        log.error(f"MQTT baglanti hatasi: {rc}")


def on_disconnect(client, userdata, rc):
    log.warning(f"MQTT baglantisi kesildi (rc={rc}).")


def on_message(client, userdata, msg):
    topic   = msg.topic
    payload = msg.payload.decode("utf-8", errors="ignore")

    log.debug(f"Mesaj alindi: {topic} -> {payload}")

    try:
        data = json.loads(payload)
    except json.JSONDecodeError:
        log.warning(f"Gecersiz JSON: {payload}")
        return

    value = data.get("value")

    if value is None:
        log.debug(f"Deger alani yok, atlaniyor: {topic}")
        return

    try:
        # Hangi sensor oldugunu belirle
        if topic == SENSOR_PATHS.get("sensors/gas"):
            log.info(f"GAZ SENSORU: {value}")
            handle_gas(int(value))

        elif topic == SENSOR_PATHS.get("sensors/flame"):
            log.info(f"YANGIN SENSORU: {value}")
            handle_flame(int(value))

        elif topic == SENSOR_PATHS.get("sensors/rain"):
            log.info(f"YAGMUR SENSORU: {value}")
            handle_rain(int(value))

        elif topic == SENSOR_PATHS.get("sensors/motion"):
            log.info(f"HAREKET SENSORU: {value}")
            handle_motion(int(value))

        elif topic == f"home/{HOME_ID}/mode/sleep":
            log.info("UYKU MODU AKTIVASYONU")
            start_sleep_mode_timer()

    except (ValueError, TypeError) as e:
        log.error(f"Deger donusturme hatasi: topic={topic}, value={value}, error={e}")
        return

    # Durum tablosunu guncelle
    for key, t in SENSOR_PATHS.items():
        if t == topic:
            sensor_name = key.replace("sensors/", "")
            state[sensor_name] = value
            log.debug(f"Durum guncellendi: {sensor_name} = {value}")
            break


def main():
    global _mqtt_client

    client = mqtt.Client(client_id=MQTT_CLIENT_LOGIC, clean_session=True)
    if MQTT_USERNAME and MQTT_PASSWORD:
        client.username_pw_set(MQTT_USERNAME, MQTT_PASSWORD)
    client.on_connect    = on_connect
    client.on_disconnect = on_disconnect
    client.on_message    = on_message

    _mqtt_client = client

    while True:
        try:
            client.connect(MQTT_BROKER, MQTT_PORT, keepalive=MQTT_KEEPALIVE)
            break
        except Exception as e:
            log.error(f"MQTT baglantisi basarisiz: {e}. {RECONNECT_DELAY}s sonra...")
            time.sleep(RECONNECT_DELAY)

    log.info("Otomasyon mantigi isleyicisi calisyor...")

    try:
        client.loop_forever()
    except KeyboardInterrupt:
        log.info("Kullanici tarafindan durduruldu.")
    finally:
        client.disconnect()
        log.info("Logic Handler kapatildi.")


if __name__ == "__main__":
    main()
