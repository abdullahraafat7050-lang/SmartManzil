#!/usr/bin/env python3
# ==================================================
# aklli_manzil - Logic Handler (Automation)
# Sensor data -> Automation decisions -> MQTT commands
# ==================================================

import json
import logging
import paho.mqtt.client as mqtt
from config import (
    MQTT_BROKER, MQTT_PORT, MQTT_KEEPALIVE, MQTT_CLIENT_LOGIC,
    MQTT_USERNAME, MQTT_PASSWORD,
    HOME_ID, GAS_ANALOG_THRESHOLD, QOS_ACTUATOR, RECONNECT_DELAY
)
import time
import threading

log = logging.getLogger(__name__)

# ── Cooldown للأتمتة (منع تكرار الأوامر بسرعة) ──
_automation_locks = {
    "gas": threading.Lock(),
    "smoke": threading.Lock(),
    "rain": threading.Lock(),
}

_last_automation = {
    "gas": 0,
    "smoke": 0,
    "rain": 0,
}

COOLDOWN_SECONDS = {
    "gas": 30,      # لا تكرر أمر الغاز أكثر من مرة كل 30 ثانية
    "smoke": 10,    # لا تكرر أمر الدخان أكثر من مرة كل 10 ثواني
    "rain": 10,     # لا تكرر أمر المطر أكثر من مرة كل 10 ثواني
}

def publish_command(mqtt_client, topic, payload):
    """نشر أمر على MQTT"""
    try:
        result = mqtt_client.publish(topic, json.dumps(payload), qos=QOS_ACTUATOR)
        log.info(f"Automation command: {topic} -> {payload}")
        return result.rc == mqtt.MQTT_ERR_SUCCESS
    except Exception as e:
        log.error(f"Automation error: {e}")
        return False

def can_execute_automation(automation_type):
    """التحقق من cooldown"""
    current_time = time.time()
    last_time = _last_automation.get(automation_type, 0)

    if current_time - last_time >= COOLDOWN_SECONDS.get(automation_type, 10):
        _last_automation[automation_type] = current_time
        return True
    return False

def handle_gas_sensor(mqtt_client, gas_value):
    """
    عند تفعيل sensor الغاز:
    - فتح المروحة
    - فتح الشباك
    """
    if gas_value >= GAS_ANALOG_THRESHOLD:
        if can_execute_automation("gas"):
            log.warning(f"GAS DETECTED! gas_value={gas_value}")

            # فتح المروحة
            publish_command(
                mqtt_client,
                f'home/{HOME_ID}/actuators/fan',
                {"path": "actuators/fan", "value": 1}
            )

            # فتح الشباك
            publish_command(
                mqtt_client,
                f'home/{HOME_ID}/actuators/windows',
                {"path": "actuators/windows", "value": "open"}
            )

def handle_smoke_sensor(mqtt_client, smoke_detected):
    """
    عند تفعيل sensor الدخان:
    - فتح الباب
    - إغلاق المروحة (إذا كانت مشغلة)
    """
    if smoke_detected:
        if can_execute_automation("smoke"):
            log.warning("SMOKE DETECTED!")

            # فتح الباب
            publish_command(
                mqtt_client,
                f'home/{HOME_ID}/actuators/doors',
                {"path": "actuators/doors", "value": "open"}
            )

            # إغلاق المروحة
            publish_command(
                mqtt_client,
                f'home/{HOME_ID}/actuators/fan',
                {"path": "actuators/fan", "value": 0}
            )

def handle_rain_sensor(mqtt_client, rain_detected):
    """
    عند تفعيل sensor المطر:
    - إغلاق الشباك (إذا كانت مفتوحة)
    """
    if rain_detected:
        if can_execute_automation("rain"):
            log.warning("RAIN DETECTED!")

            # إغلاق الشباك
            publish_command(
                mqtt_client,
                f'home/{HOME_ID}/actuators/windows',
                {"path": "actuators/windows", "value": "close"}
            )

def process_sensor_data(mqtt_client, topic, payload):
    """
    معالجة sensor data وتنفيذ automation logic
    يتم استدعاؤها من serial_reader.py عند استقبال sensor data
    """
    try:
        data = json.loads(payload)
    except:
        return

    value = data.get("value")

    # معالجة كل sensor
    if "gas_analog" in topic:
        handle_gas_sensor(mqtt_client, value)

    elif "flame" in topic or "smoke" in topic:
        # تحويل القيمة إلى boolean
        smoke_detected = value == 1 or str(value).lower() in ["1", "true", "on"]
        handle_smoke_sensor(mqtt_client, smoke_detected)

    elif "rain" in topic:
        # تحويل القيمة إلى boolean
        rain_detected = value == 1 or str(value).lower() in ["1", "true", "on"]
        handle_rain_sensor(mqtt_client, rain_detected)

def on_connect(client, userdata, flags, rc):
    if rc == 0:
        log.info("MQTT broker'a baglandi (Logic Handler).")
        # الاشتراك في sensor topics
        client.subscribe("home/home_001/sensors/#", qos=0)
        log.info("Abone olundu: home/home_001/sensors/#")
    else:
        log.error(f"MQTT baglanti hatasi: {rc}")

def on_message(client, userdata, msg):
    """استقبال sensor data وتنفيذ automation"""
    topic = msg.topic
    payload = msg.payload.decode("utf-8", errors="ignore")

    log.debug(f"Sensor data: {topic} -> {payload}")
    process_sensor_data(client, topic, payload)

def main():
    client = mqtt.Client(client_id=MQTT_CLIENT_LOGIC, clean_session=True)
    if MQTT_USERNAME and MQTT_PASSWORD:
        client.username_pw_set(MQTT_USERNAME, MQTT_PASSWORD)
    client.on_connect = on_connect
    client.on_message = on_message

    while True:
        try:
            client.connect(MQTT_BROKER, MQTT_PORT, keepalive=MQTT_KEEPALIVE)
            break
        except Exception as e:
            log.error(f"MQTT baglantisi basarisiz: {e}. {RECONNECT_DELAY}s sonra tekrar...")
            time.sleep(RECONNECT_DELAY)

    log.info("Logic Handler basladi...")
    client.loop_forever()

if __name__ == "__main__":
    main()
