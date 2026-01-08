# Health System Tool v1.1

A professional, lightweight **Bash-based** system monitor for Linux. This tool provides real-time diagnostics, forensic logging, and security auditing with zero external database dependencies.

## New in v1.1 (Universal & Flicker-Free)
* **Atomic Rendering**: Advanced ANSI escape sequences (`printf \033[H\033[J`) provide a smooth, `top`-like experience without screen flickering.
* **Black Box Forensic Logging**: Automatically saves a process snapshot to `/var/log/system_crisis.log` when the system reaches critical load (RAM > 90% or CPU Saturation > 90%).
* **Security Audit**: Real-time tracking of active **SSH Sessions** and network interfaces to detect unauthorized access.
* **Docker & Universal Support**: Fully compatible with Fedora, Ubuntu, and Alpine Linux (Docker). Detects network routes dynamically without `ifconfig`.
* **Safety Handling**: Implements `trap` signals to ensure a clean terminal exit and automatic cursor recovery.

## Features
* **Dynamic Visualization**: Color-coded progress bars (Green/Yellow/Red) for CPU, RAM, and Disk usage.
* **Process Audit**: Comprehensive tracking of Total, Running, Sleeping, Stopped, and **Zombie** processes.
* **Network Intelligence**: Detects active Local IP (via gateway route), Public IP, and active SSH connections.

## Project Structure
* `health-check.sh`: The core monitoring engine.
* `Dockerfile`: Lightweight Alpine-based containerization.
* `docker-compose.yml`: Optimized network (host mode) and log persistence.
* `logs/`: Directory for persistent forensic records.

## Installation & Usage

### 1. Direct Execution (Local)
```bash
chmod +x health-check.sh
./health-check.sh
```
### 2. Build the image
Package the script and its dependencies (based on Alpine Linux):
```bash
sudo docker-compose build --no-cache
sudo docker-compose run --rm monitor
```
