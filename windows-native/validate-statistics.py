#!/usr/bin/env python3
"""
Validation Script for Statistical Features Implementation
Tests that min, max, std, range, and sample_count are being collected
"""

import paho.mqtt.client as mqtt
import json
import time
from datetime import datetime

# Configuration
MQTT_BROKER = "localhost"  # Change to your broker IP if needed
MQTT_PORT = 1883
MQTT_TOPIC = "power_monitoring/#"

# Test counters
messages_received = 0
messages_with_stats = 0
machines_seen = set()

def on_connect(client, userdata, flags, rc):
    print(f"✓ Connected to MQTT broker at {MQTT_BROKER}:{MQTT_PORT}")
    print(f"✓ Subscribing to topic: {MQTT_TOPIC}")
    client.subscribe(MQTT_TOPIC)
    print("\n📊 Waiting for messages with statistical features...\n")

def on_message(client, userdata, msg):
    global messages_received, messages_with_stats, machines_seen
    
    try:
        data = json.loads(msg.payload.decode())
        messages_received += 1
        
        machine = data.get('machine', 'Unknown')
        phase = data.get('phase', 'Unknown')
        machines_seen.add(machine)
        
        # Check for statistical features
        has_stats = all(field in data for field in [
            'current_mean', 'current_min', 'current_max', 
            'current_std', 'current_range', 'sample_count'
        ])
        
        if has_stats:
            messages_with_stats += 1
            print(f"✅ {datetime.now().strftime('%H:%M:%S')} - {machine} / Phase {phase}")
            print(f"   Mean: {data.get('current_mean', 0):.3f}A  "
                  f"Min: {data.get('current_min', 0):.3f}A  "
                  f"Max: {data.get('current_max', 0):.3f}A")
            print(f"   Std: {data.get('current_std', 0):.3f}A  "
                  f"Range: {data.get('current_range', 0):.3f}A  "
                  f"Samples: {data.get('sample_count', 0)}")
            print()
        else:
            print(f"⚠️  {datetime.now().strftime('%H:%M:%S')} - {machine} / Phase {phase} "
                  f"- MISSING statistical features")
            missing = [field for field in [
                'current_mean', 'current_min', 'current_max', 
                'current_std', 'current_range', 'sample_count'
            ] if field not in data]
            print(f"   Missing fields: {', '.join(missing)}")
            print()
            
    except json.JSONDecodeError:
        print(f"❌ Invalid JSON from {msg.topic}")
    except Exception as e:
        print(f"❌ Error processing message: {e}")

def on_disconnect(client, userdata, rc):
    print(f"\n⚠️  Disconnected from broker (code: {rc})")

def main():
    print("="*70)
    print("Statistical Features Validation Script")
    print("="*70)
    print()
    
    client = mqtt.Client()
    client.on_connect = on_connect
    client.on_message = on_message
    client.on_disconnect = on_disconnect
    
    try:
        client.connect(MQTT_BROKER, MQTT_PORT, 60)
        client.loop_start()
        
        # Run for 30 seconds
        print("⏱️  Testing for 30 seconds...")
        time.sleep(30)
        
        client.loop_stop()
        client.disconnect()
        
    except KeyboardInterrupt:
        print("\n\n⚠️  Interrupted by user")
        client.loop_stop()
        client.disconnect()
    except Exception as e:
        print(f"\n❌ Connection error: {e}")
        return
    
    # Print summary
    print("\n" + "="*70)
    print("SUMMARY")
    print("="*70)
    print(f"Total messages received: {messages_received}")
    print(f"Messages with statistics: {messages_with_stats}")
    print(f"Machines detected: {', '.join(sorted(machines_seen)) if machines_seen else 'None'}")
    
    if messages_received > 0:
        success_rate = (messages_with_stats / messages_received) * 100
        print(f"\nSuccess rate: {success_rate:.1f}%")
        
        if success_rate == 100:
            print("\n✅ SUCCESS! All messages contain statistical features.")
        elif success_rate > 0:
            print(f"\n⚠️  PARTIAL: {messages_with_stats}/{messages_received} messages have statistics.")
            print("   Some machines may not be updated yet.")
        else:
            print("\n❌ FAILED: No messages contain statistical features.")
            print("   Check that Pi containers have been restarted.")
    else:
        print("\n⚠️  No messages received. Check:")
        print("   - MQTT broker is running")
        print("   - Pi containers are running")
        print("   - Network connectivity")

if __name__ == "__main__":
    main()
