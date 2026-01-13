@echo off
REM Analysis API Service Startup Script

cd /d "C:\Users\alfredoziccardi\~\PowerUniversitySolution\analysis\code"

REM Set environment variables for InfluxDB connection
set INFLUX_TOKEN=YOUR_INFLUXDB_TOKEN_HERE
set INFLUX_URL=http://localhost:8086
set INFLUX_ORG=DataImage

REM Start the analysis API server
python main.py --log info --module_config "..\config\module_config.toml" --user_config "..\config\user_config.toml"
