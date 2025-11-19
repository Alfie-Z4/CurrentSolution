# Centralized Deployment Guide

## Architecture Overview

### Central Server
Runs all services EXCEPT current-sensing:
- **MQTT Broker** (port 1883) - Receives data from all Pis
- **InfluxDB** (port 8086) - Stores time-series data
- **Telegraf** - Transfers MQTT data to InfluxDB
- **Grafana** (port 3000) - Dashboards
- **Analysis Module** - Power calculations
- **Graph UI** (port 80) - Web interface

### Raspberry Pis (x5)
Each Pi runs only:
- **current-sensing** - Measures current and publishes to central MQTT

---

## Setup Instructions

### 1. Central Server Setup

#### Prerequisites
- Docker and Docker Compose installed
- Ports 1883, 3000, 8086, 80 available
- Static IP address recommended

#### Steps

1. **Navigate to project directory:**
   ```bash
   cd PowerUniversitySolution
   ```

2. **Update MQTT broker configuration:**
   Edit `mqtt_broker/mosquitto.conf`:
   ```conf
   listener 1883 0.0.0.0
   allow_anonymous true
   ```

3. **Start all services:**
   ```bash
   docker-compose -f docker-compose-central.yml up -d
   ```

4. **Verify services are running:**
   ```bash
   docker-compose -f docker-compose-central.yml ps
   ```

   Expected output:
   ```
   mqtt_broker           running
   timeseries-db         running
   timeseries-db-input   running
   dashboard             running
   analysis              running
   graph                 running
   ```

5. **Check logs:**
   ```bash
   docker-compose -f docker-compose-central.yml logs -f
   ```

6. **Access Grafana:**
   - URL: `http://<server-ip>:3000`
   - Default login: `admin` / `admin`

---

### 2. Raspberry Pi Setup (Repeat for each Pi)

#### Prerequisites
- Docker and Docker Compose installed
- Network connectivity to central server
- I2C/SPI enabled for sensors

#### Steps for Pi #1

1. **Navigate to project directory:**
   ```bash
   cd PowerUniversitySolution
   ```

2. **Configure MQTT connection:**
   
   Edit `current_sensing/config/user_config.toml` (or your chosen pm_*.toml):
   ```toml
   [mqtt]
       broker = "192.168.1.100"  # CHANGE TO YOUR CENTRAL SERVER IP
       port = 1883
       topic_prefix = ""
   
   [calculation.machine_name]
       module = "gen_constants"
       class = "ConstantSet"
   [calculation.machine_name.config]
       machine = "Pi_1"  # UNIQUE NAME FOR THIS PI
   ```

3. **Start current-sensing service:**
   ```bash
   docker-compose -f docker-compose-pi.yml up -d
   ```

4. **Verify it's running:**
   ```bash
   docker-compose -f docker-compose-pi.yml ps
   docker-compose -f docker-compose-pi.yml logs -f current-sensing
   ```

   Look for: `Connected!` and `pub topic:power_monitoring/Pi_1`

5. **Test MQTT connectivity:**
   ```bash
   # On central server, subscribe to MQTT:
   docker exec -it <mqtt_broker_container> mosquitto_sub -t "power_monitoring/#" -v
   
   # You should see messages from Pi_1
   ```

#### Steps for Pi #2, #3, #4, #5

Repeat above steps but change:
- `machine = "Pi_2"` (then Pi_3, Pi_4, Pi_5)
- Keep same central server IP in `broker` field

---

### 3. Configure Analysis Module for Multiple Machines

Edit `analysis/config/user_config.toml` on central server:

```toml
[config.power_factor]
    default = 1

    [config.power_factor.machines]
        Pi_1 = 0.95
        Pi_2 = 0.95
        Pi_3 = 0.95
        Pi_4 = 0.95
        Pi_5 = 0.95

[config.voltage_line_neutral]
    default = 230

    [config.voltage_line_neutral.machines]
        Pi_1 = 230
        Pi_2 = 230
        Pi_3 = 230
        Pi_4 = 230
        Pi_5 = 230
```

Restart analysis service:
```bash
docker-compose -f docker-compose-central.yml restart analysis
```

---

### 4. Configure Grafana for Multiple Machines

1. **Access Grafana:** `http://<server-ip>:3000`

2. **Navigate to existing dashboard or create new one**

3. **Add/Edit dashboard variable:**
   - Settings → Variables → Add variable
   - Name: `machine`
   - Type: `Custom`
   - Values: `Pi_1, Pi_2, Pi_3, Pi_4, Pi_5`

   OR use Query to auto-discover:
   - Type: `Query`
   - Data source: `InfluxDB`
   - Query:
     ```flux
     import "influxdata/influxdb/schema"
     
     schema.tagValues(
       bucket: "power_monitoring",
       tag: "machine",
       predicate: (r) => true,
       start: -30d
     )
     ```

4. **View all machines on one graph:**
   - Use InfluxDB data source
   - Don't filter by machine tag
   - All machines will appear as separate series

---

## Network Configuration

### Firewall Rules (Central Server)

Allow incoming connections on:
- **1883** - MQTT (from all Pis)
- **3000** - Grafana (from your network)
- **8086** - InfluxDB (optional, for direct access)
- **80** - Graph UI (optional)

Example (Ubuntu/Debian):
```bash
sudo ufw allow 1883/tcp
sudo ufw allow 3000/tcp
sudo ufw allow 8086/tcp
sudo ufw allow 80/tcp
```

### Static IP Recommendation

Set static IP for central server to avoid reconfiguring all Pis.

---

## Troubleshooting

### Pi cannot connect to MQTT broker

1. **Check network connectivity:**
   ```bash
   ping <central-server-ip>
   telnet <central-server-ip> 1883
   ```

2. **Check firewall on central server**

3. **Check MQTT broker logs:**
   ```bash
   docker-compose -f docker-compose-central.yml logs mqtt_broker
   ```

### No data in Grafana

1. **Check if data is in InfluxDB:**
   - Access InfluxDB: `http://<server-ip>:8086`
   - Query: `from(bucket: "power_monitoring") |> range(start: -1h)`

2. **Check Telegraf logs:**
   ```bash
   docker-compose -f docker-compose-central.yml logs timeseries-db-input
   ```

3. **Verify MQTT messages:**
   ```bash
   docker exec -it <mqtt_broker_container> mosquitto_sub -t "power_monitoring/#" -v
   ```

### Dashboard shows no power values

1. **Check Analysis Module logs:**
   ```bash
   docker-compose -f docker-compose-central.yml logs analysis
   ```

2. **Verify machine names match** in:
   - Pi config files
   - Analysis config file
   - Grafana dashboard variables

---

## Maintenance Commands

### Central Server

```bash
# Stop all services
docker-compose -f docker-compose-central.yml down

# Start all services
docker-compose -f docker-compose-central.yml up -d

# Restart specific service
docker-compose -f docker-compose-central.yml restart analysis

# View logs
docker-compose -f docker-compose-central.yml logs -f

# Update and rebuild
docker-compose -f docker-compose-central.yml pull
docker-compose -f docker-compose-central.yml up -d --build
```

### Raspberry Pi

```bash
# Stop current-sensing
docker-compose -f docker-compose-pi.yml down

# Start current-sensing
docker-compose -f docker-compose-pi.yml up -d

# View logs
docker-compose -f docker-compose-pi.yml logs -f current-sensing

# Update and rebuild
docker-compose -f docker-compose-pi.yml up -d --build
```

---

## Data Flow

```
[Pi #1] → MQTT (1883) → [Central Server]
[Pi #2] → MQTT (1883) → [Central Server]
[Pi #3] → MQTT (1883) → [Central Server]
[Pi #4] → MQTT (1883) → [Central Server]
[Pi #5] → MQTT (1883) → [Central Server]
                            ↓
                       [Telegraf]
                            ↓
                       [InfluxDB]
                            ↓
              [Analysis Module] ← [Grafana]
```

1. Each Pi measures current
2. Publishes to `power_monitoring/{machine}/{phase}` topic
3. Central MQTT broker receives all messages
4. Telegraf subscribes to MQTT and writes to InfluxDB
5. Grafana queries Analysis Module
6. Analysis Module reads from InfluxDB and calculates power
7. Grafana displays results

---

## Success Indicators

✅ **Central Server:**
- All 6 containers running
- Grafana accessible at port 3000
- MQTT listening on port 1883

✅ **Each Pi:**
- 1 container running (current-sensing)
- Logs show "Connected!" to MQTT
- Logs show "pub topic:power_monitoring/Pi_X"

✅ **Grafana:**
- Can select all machine names in variables
- Data appears on dashboards for all machines
- Real-time updates every few seconds
