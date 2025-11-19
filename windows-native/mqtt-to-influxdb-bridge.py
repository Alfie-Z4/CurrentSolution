"""
MQTT to InfluxDB Bridge - Windows Native Version
Replaces Telegraf for Windows native installation
Subscribes to MQTT topics and writes data to InfluxDB
"""

import paho.mqtt.client as mqtt
from influxdb_client import InfluxDBClient, Point, WritePrecision
from influxdb_client.client.write_api import SYNCHRONOUS
from datetime import datetime
import json
import os
import sys
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('C:\\Logs\\mqtt-bridge.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

# Configuration from environment variables (set these in Windows)
MQTT_BROKER = os.getenv('MQTT_BROKER', 'localhost')
MQTT_PORT = int(os.getenv('MQTT_PORT', '1883'))
MQTT_TOPIC = os.getenv('MQTT_TOPIC', 'power_monitoring/#')

INFLUX_URL = os.getenv('INFLUX_URL', 'http://localhost:8086')
INFLUX_TOKEN = os.getenv('INFLUX_TOKEN', '')  # Set this!
INFLUX_ORG = os.getenv('INFLUX_ORG', 'DataImage')
INFLUX_BUCKET = os.getenv('INFLUX_BUCKET', 'power_monitoring')

# Validate configuration
if not INFLUX_TOKEN:
    logger.error("INFLUX_TOKEN environment variable not set!")
    logger.error("Set it with: setx INFLUX_TOKEN \"your-token-here\"")
    sys.exit(1)

# Initialize InfluxDB client
try:
    influx_client = InfluxDBClient(url=INFLUX_URL, token=INFLUX_TOKEN, org=INFLUX_ORG)
    write_api = influx_client.write_api(write_options=SYNCHRONOUS)
    logger.info(f"Connected to InfluxDB at {INFLUX_URL}")
except Exception as e:
    logger.error(f"Failed to connect to InfluxDB: {e}")
    sys.exit(1)

# MQTT callbacks
def on_connect(client, userdata, flags, rc):
    """Callback when connected to MQTT broker"""
    if rc == 0:
        logger.info(f"Connected to MQTT broker at {MQTT_BROKER}:{MQTT_PORT}")
        client.subscribe(MQTT_TOPIC)
        logger.info(f"Subscribed to topic: {MQTT_TOPIC}")
    else:
        logger.error(f"Failed to connect to MQTT broker, return code: {rc}")

def on_disconnect(client, userdata, rc):
    """Callback when disconnected from MQTT broker"""
    if rc != 0:
        logger.warning(f"Unexpected disconnection from MQTT broker. Code: {rc}")
    else:
        logger.info("Disconnected from MQTT broker")

def on_message(client, userdata, msg):
    """Callback when MQTT message received"""
    try:
        # Parse topic: power_monitoring/machine_name/phase or power_monitoring/machine_name
        topic_parts = msg.topic.split('/')
        
        if len(topic_parts) < 2:
            logger.warning(f"Invalid topic format: {msg.topic}")
            return
        
        # Extract machine name
        machine = topic_parts[1]
        phase = topic_parts[2] if len(topic_parts) > 2 else "total"
        
        # Parse JSON payload
        try:
            data = json.loads(msg.payload.decode())
        except json.JSONDecodeError:
            logger.warning(f"Invalid JSON from {msg.topic}: {msg.payload}")
            return
        
        # Extract timestamp (use received time if not in message)
        timestamp = data.get('timestamp', datetime.utcnow().isoformat())
        
        # Create InfluxDB point
        point = Point("equipment_power_usage") \
            .tag("machine", machine) \
            .tag("phase", phase)
        
        # Add fields from data
        field_mappings = {
            'current': 'current',
            'voltage': 'voltage',
            'power': 'power_real',
            'power_real': 'power_real',
            'power_apparent': 'power_apparent',
            'power_reactive': 'power_reactive',
            'frequency': 'frequency',
            'power_factor': 'power_factor',
            'energy': 'energy'
        }
        
        fields_added = 0
        for msg_field, influx_field in field_mappings.items():
            if msg_field in data:
                try:
                    point.field(influx_field, float(data[msg_field]))
                    fields_added += 1
                except (ValueError, TypeError):
                    logger.warning(f"Invalid value for {msg_field}: {data[msg_field]}")
        
        if fields_added == 0:
            logger.warning(f"No valid fields in message from {msg.topic}")
            return
        
        # Set timestamp
        point.time(timestamp, WritePrecision.NS)
        
        # Write to InfluxDB
        write_api.write(bucket=INFLUX_BUCKET, org=INFLUX_ORG, record=point)
        
        logger.debug(f"Stored: {machine}/{phase} - {fields_added} fields")
        
    except Exception as e:
        logger.error(f"Error processing message from {msg.topic}: {e}")

def main():
    """Main function"""
    logger.info("=" * 60)
    logger.info("MQTT to InfluxDB Bridge - Starting")
    logger.info("=" * 60)
    logger.info(f"MQTT Broker: {MQTT_BROKER}:{MQTT_PORT}")
    logger.info(f"MQTT Topic: {MQTT_TOPIC}")
    logger.info(f"InfluxDB URL: {INFLUX_URL}")
    logger.info(f"InfluxDB Org: {INFLUX_ORG}")
    logger.info(f"InfluxDB Bucket: {INFLUX_BUCKET}")
    logger.info("=" * 60)
    
    # Create MQTT client
    mqtt_client = mqtt.Client(client_id="influxdb_bridge")
    mqtt_client.on_connect = on_connect
    mqtt_client.on_disconnect = on_disconnect
    mqtt_client.on_message = on_message
    
    # Connect to MQTT broker
    try:
        mqtt_client.connect(MQTT_BROKER, MQTT_PORT, 60)
        logger.info("Starting MQTT loop...")
        mqtt_client.loop_forever()
    except KeyboardInterrupt:
        logger.info("Shutting down gracefully...")
        mqtt_client.disconnect()
        influx_client.close()
    except Exception as e:
        logger.error(f"Fatal error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
