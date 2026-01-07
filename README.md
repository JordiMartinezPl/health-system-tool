# Health System Tool v1.1

A professional, lightweight **Bash-based** system monitor for Linux. This tool provides real-time diagnostics, forensic logging, and security auditing with zero external database dependencies.

##  New in v1.1
* **Black Box Forensic Logging**: Automatically saves a process snapshot to `/var/log/system_crisis.log` when the system reaches critical load (RAM > 90% or Load > 5.0).
* **Security Audit**: Real-time tracking of **Listening Ports** and active **SSH Sessions** to detect unauthorized access.
* **Global Installer**: Now includes a `Makefile` for system-wide installation.
* **Safety Handling**: Implements `trap` signals to ensure a clean terminal exit and dependency checks on startup.

## Features
* **Dynamic Visualization**: Color-coded progress bars (Green/Yellow/Red) for RAM and Disk usage.
* **Process Audit**: Tracks Total, Zombie, Stopped, and Sleeping processes.
* **Network Intelligence**: Tracks Interface state, Local IP, Public IP, and active connections.

##  Installation & Update
To install or update to the latest version, run:

```bash
git clone [https://github.com/your-username/health-system-tool.git](https://github.com/your-username/health-system-tool.git)
cd health-system-tool
sudo make install
```
