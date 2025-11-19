# Power Monitoring Solution - DataImage

## Overview
Real-time power monitoring for industrial equipment using current sensors, MQTT, InfluxDB, and Grafana.

## Quick Start
For production deployment on Windows Server with Raspberry Pi sensors, see:
- [WINDOWS_SETUP_GUIDE.md](WINDOWS_SETUP_GUIDE.md) - Complete setup guide for centralized architecture
- [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) - Deployment procedures

## Configure
Edit the text files at `/current_sensing/config/user_config.toml` and `/analysis/config/user_config.toml`
## Build
Build using docker: `docker compose build`
## Run
Run using the `./start.sh` script. 
## Usage
View Grafana dashboards in a web browser: `localhost:3000` 
