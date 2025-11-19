# Quick Start Guide - Centralized Deployment

## Summary

**You're correct!** On each Pi, you do **NOT** run the MQTT broker.

### What Runs Where:

| Component | Central Server | Raspberry Pi (x5) |
|-----------|----------------|-------------------|
| MQTT Broker | ✅ YES | ❌ NO |
| InfluxDB | ✅ YES | ❌ NO |
| Telegraf | ✅ YES | ❌ NO |
| Grafana | ✅ YES | ❌ NO |
| Analysis Module | ✅ YES | ❌ NO |
| Graph UI | ✅ YES | ❌ NO |
| current-sensing | ❌ NO | ✅ YES |

---

## Central Server - How to Run All Services

### Step 1: Prepare Configuration

No code changes needed! Just use the provided `docker-compose-central.yml`

### Step 2: Start All Services

```bash
# Navigate to project directory
cd PowerUniversitySolution

# Start all services with one command
docker-compose -f docker-compose-central.yml up -d
```

That's it! This single command starts:
- MQTT Broker (receives data from Pis)
- InfluxDB (stores data)
- Telegraf (MQTT → InfluxDB)
- Grafana (dashboards)
- Analysis Module (power calculations)
- Graph UI (web interface)

### Step 3: Verify Services

```bash
# Check all containers are running
docker-compose -f docker-compose-central.yml ps

# Expected output:
# NAME                  STATUS
# mqtt_broker           Up
# timeseries-db         Up
# timeseries-db-input   Up
# dashboard             Up
# analysis              Up
# graph                 Up
```

### Step 4: Access Services

- **Grafana:** http://YOUR-SERVER-IP:3000 (login: admin/admin)
- **Graph UI:** http://YOUR-SERVER-IP:80
- **InfluxDB:** http://YOUR-SERVER-IP:8086
- **MQTT Broker:** YOUR-SERVER-IP:1883 (for Pis to connect)

### Manage Services

```bash
# Stop all services
docker-compose -f docker-compose-central.yml down

# Restart all services
docker-compose -f docker-compose-central.yml restart

# View logs
docker-compose -f docker-compose-central.yml logs -f

# View specific service logs
docker-compose -f docker-compose-central.yml logs -f grafana
```

---

## Raspberry Pi Setup (Each Device)

### Step 1: Configure MQTT Connection

Edit your config file (e.g., `current_sensing/config/pm_b_3pu_mock.toml`):

Find the `[mqtt]` section and change:

```toml
[mqtt]
    broker = "192.168.1.100"  # <-- YOUR CENTRAL SERVER IP
    port = 1883
```

Find the machine name section and make it unique:

```toml
[calculation.machine_name.config]
    machine = "Pi_1"  # <-- Pi_1, Pi_2, Pi_3, Pi_4, or Pi_5
```

### Step 2: Start Current Sensing Service

```bash
# Navigate to project directory
cd PowerUniversitySolution

# Start only current-sensing
docker-compose -f docker-compose-pi.yml up -d
```

### Step 3: Verify Connection

```bash
# Check container is running
docker-compose -f docker-compose-pi.yml ps

# Check logs for successful connection
docker-compose -f docker-compose-pi.yml logs -f current-sensing

# Look for these messages:
# "connecting to 192.168.1.100:1883"
# "Connected!"
# "pub topic:power_monitoring/Pi_1/A"
```

---

## How Data Flows

```
┌─────────────┐
│   Pi #1     │──┐
│(sensing only)│  │
└─────────────┘  │
                 │
┌─────────────┐  │     ┌──────────────────────────────┐
│   Pi #2     │──┤     │     Central Server           │
│(sensing only)│  ├────►│                              │
└─────────────┘  │     │  ┌────────────────┐          │
                 │     │  │  MQTT Broker   │          │
┌─────────────┐  │     │  └────────┬───────┘          │
│   Pi #3     │──┤     │           │                  │
│(sensing only)│  │     │  ┌────────▼───────┐         │
└─────────────┘  │     │  │   Telegraf     │         │
                 │     │  └────────┬───────┘         │
┌─────────────┐  │     │           │                  │
│   Pi #4     │──┤     │  ┌────────▼───────┐         │
│(sensing only)│  │     │  │   InfluxDB     │         │
└─────────────┘  │     │  └────────┬───────┘         │
                 │     │           │                  │
┌─────────────┐  │     │  ┌────────▼───────┐         │
│   Pi #5     │──┘     │  │   Analysis     │         │
│(sensing only)│        │  └────────┬───────┘         │
└─────────────┘        │           │                  │
                       │  ┌────────▼───────┐         │
                       │  │    Grafana     │         │
                       │  └────────────────┘         │
                       └──────────────────────────────┘
```

1. Each Pi measures current from sensors
2. Pi publishes MQTT message to central server
3. Central MQTT broker receives all messages
4. Telegraf reads MQTT → writes to InfluxDB
5. InfluxDB stores: current, timestamp, machine, phase
6. Grafana queries Analysis Module
7. Analysis Module reads InfluxDB, calculates power
8. Grafana displays results

---

## Testing the Setup

### Test 1: MQTT Connection (from any Pi)

```bash
# Install mosquitto-clients on Pi (if needed)
sudo apt-get install mosquitto-clients

# Subscribe to MQTT broker on central server
mosquitto_sub -h 192.168.1.100 -t "power_monitoring/#" -v

# You should see messages like:
# power_monitoring/Pi_1/A {"timestamp":"2025-11-18T12:34:56", "current":10.5, "machine":"Pi_1", "phase":"A"}
```

### Test 2: InfluxDB Data (on central server)

```bash
# Access InfluxDB web UI
http://YOUR-SERVER-IP:8086

# Or use CLI to query
docker exec -it <influxdb-container> influx query 'from(bucket:"power_monitoring") |> range(start:-1h)'
```

### Test 3: Grafana (on central server)

1. Open: http://YOUR-SERVER-IP:3000
2. Login: admin / admin
3. Go to Dashboards → Browse → Power Monitoring
4. Select machine: Pi_1, Pi_2, etc.
5. You should see live data updating

---

## Common Issues

### "Cannot connect to MQTT broker"

**On Pi:** Check if central server is reachable
```bash
ping 192.168.1.100
telnet 192.168.1.100 1883
```

**On Central Server:** Check firewall
```bash
sudo ufw allow 1883/tcp
```

### "No data in Grafana"

1. Check MQTT messages arriving:
   ```bash
   docker-compose -f docker-compose-central.yml logs mqtt_broker
   ```

2. Check Telegraf is writing to InfluxDB:
   ```bash
   docker-compose -f docker-compose-central.yml logs timeseries-db-input
   ```

3. Verify data in InfluxDB (see Test 2 above)

### "Container won't start"

```bash
# Check logs for specific service
docker-compose -f docker-compose-central.yml logs <service-name>

# Rebuild containers
docker-compose -f docker-compose-central.yml up -d --build
```

---

## Network Requirements

### Central Server Firewall

Allow incoming on these ports:
- **1883** - MQTT (from all Pis)
- **3000** - Grafana (from your network)
- **8086** - InfluxDB (optional)
- **80** - Graph UI (optional)

### Raspberry Pi Network

Must be able to reach:
- Central Server IP on port **1883**

### Recommended

- Assign **static IP** to central server
- Keep all devices on same network/VLAN
- Use reliable network switches

---

## File Summary

Files created for you:

1. **docker-compose-central.yml** - Run on central server
2. **docker-compose-pi.yml** - Run on each Pi
3. **DEPLOYMENT_GUIDE.md** - Detailed instructions
4. **EXAMPLE_PI_CONFIG.toml** - Template for Pi configuration
5. **QUICK_START.md** - This file

Files to modify:

1. **mqtt_broker/mosquitto.conf** - Already updated to accept remote connections
2. **current_sensing/config/[your-config].toml** - Update broker IP and machine name on each Pi
3. **analysis/config/user_config.toml** - Add all machine names with voltage/power factor

---

## Next Steps

1. ✅ Files are created and ready
2. ⏭️ Deploy central server: `docker-compose -f docker-compose-central.yml up -d`
3. ⏭️ Configure each Pi with unique machine name
4. ⏭️ Deploy to each Pi: `docker-compose -f docker-compose-pi.yml up -d`
5. ⏭️ Access Grafana and verify data

You're all set! 🚀
