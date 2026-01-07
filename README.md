# health-system-tool

A lightweight **Bash-based** system monitor for Linux environments. This tool provides real-time diagnostics of hardware resources, network status, and process management.

## Features

* **Passive Network Monitoring**: Retrieves interface state from `/sys/class/net/` to avoid network overhead.
* **Dynamic Visualization**: Progress bars with `printf` that update based on **RAM** and **Disk** load.
* **Dual IP Tracking**: Captures both **Private IP** (via `hostname`) and **Public IP** (via `curl`).
* **Process Audit**: Tracks **Total**, **Zombie**, **Stopped**, and **Sleeping** process counts.
* **Resource Guard**: Automatically lists top memory-consuming processes when RAM usage exceeds 90%.

## Installation

git clone [https://github.com/your-username/health-system-tool.git](https://github.com/your-username/health-system-tool.git)
cd health-system-tool
chmod +x health-check.sh

### Usage

./health-check.sh
Technical Specifications
Architecture
Optimized for minimal CPU impact by reading from /proc and /sys virtual filesystems. This ensures the monitor remains lightweight even during high system loads.

### Formatting
Alignment: Uses printf for fixed-width alignment, ensuring the dashboard remains consistent across different terminal sizes.

Colors: ANSI escape codes are used for real-time status coloring (Green/Yellow/Red).

### Dependencies
awk

grep

curl

iproute2
