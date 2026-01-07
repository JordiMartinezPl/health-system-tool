#!/bin/bash

USER=$(whoami)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NO_COLOR='\033[0m'

LOG_FILE="/var/log/system_crisis.log"

# HELP MENU
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    echo -e "${YELLOW}Health System Tool v1.1${NO_COLOR}"
    echo "Usage: ./health-check.sh"
    echo ""
    echo "Description: Real-time monitor for CPU, RAM, Disk, and Network."
    echo "Features:"
    echo "  - Crisis snapshots saved to $LOG_FILE"
    echo "  - Dependency check on startup"
    echo "  - SSH intrusion detection"
    exit 0
fi

# DEPENDENCY CHECK
for cmd in curl awk ss ps free df hostname; do
    if ! command -v $cmd &> /dev/null; then
        echo -e "${RED}Error: Required command '$cmd' is not installed.${NO_COLOR}"
        exit 1
    fi
done

# CLEAN EXIT (Fixed SIGINT typo)
clean_exit(){
    echo -e "${NO_COLOR}\n[!] Monitor stopped by user. Cleaning up..."
    exit 0
}
trap clean_exit SIGINT SIGTERM

# NET INITIAL DATA
PUBLIC_IP=$(curl -s --max-time 2 ifconfig.me)
[ -z "$PUBLIC_IP" ] && PUBLIC_IP="Unknown net"

draw_bar(){
    local percentage=$1
    local width=20
    local filled=$((percentage * width / 100))
    local empty=$((width - filled))
    local COLOR=$GREEN
    [ $percentage -ge 70 ] && COLOR=$YELLOW
    [ $percentage -ge 90 ] && COLOR=$RED

    printf "["
    printf "${COLOR}"
    printf "%${filled}s" | tr ' ' '#'
    printf "${NO_COLOR}"
    printf "%${empty}s" | tr ' ' '-'
    printf "] %d%%" "$percentage"
}

while true; do
    clear
    DATE=$(date +%D" "%H:%M:%S)
    UPTIME_SYSTEM=$(uptime -p)
    ACTIVE_SESSION_COUNT=$(who | wc -l)
    LOAD_CPU=$(cat /proc/loadavg | awk '{print $1, $2, $3}')
    LOAD_VAL=$(echo $LOAD_CPU | awk -F'[,.]' '{print $1}')

    TOTAL_PROC=$(ps aux | wc -l | awk '{print $1 - 1}')
    ZOMBIES=$(ps aux | awk '$8=="Z"' | wc -l)
    STOPPED_PROC=$(ps axo state | grep -c "T")
    SLEEP_PROC=$(ps axo state | grep -c "S")

    TOTAL_RAM=$(free -m | grep Mem | awk '{print $2}')
    USED_RAM=$(free -m | grep Mem | awk '{print $3}')
    PERCENTAGE_RAM=$((USED_RAM*100/TOTAL_RAM))

    DISK_USAGE=$(df / --output=pcent | grep -oP '\d+' | head -n1)

    INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
    NET_STATE=$(cat /sys/class/net/$INTERFACE/operstate 2>/dev/null || echo "down")
    CONN_COUNT=$(ss -tun | grep -c "ESTAB")
    LOCAL_IP=$(hostname -I | awk '{print $1}')

    OPEN_PORTS=$(ss -tuln | grep LISTEN | awk '{print $5}' | cut -d':' -f2 | sort -u | tr '\n' ' ')
    SSH_SESSIONS=$(ss -tun | grep -c ":22")

    echo -e "${YELLOW}==========================================================${NO_COLOR}"
    echo -e " HEALTH REPORT - $DATE"
    echo -e "${YELLOW}==========================================================${NO_COLOR}"
    echo "User: $USER    Host: $(hostname)    Uptime: $UPTIME_SYSTEM"
    echo -e "CPU LOAD: $LOAD_CPU | Total Proc: $TOTAL_PROC"
    echo -e "${RED}Zombies: $ZOMBIES${NO_COLOR} | ${YELLOW}Stopped: $STOPPED_PROC${NO_COLOR} | Sleep: $SLEEP_PROC"
    echo "Active sessions: $ACTIVE_SESSION_COUNT"
    echo "Local IP: $LOCAL_IP  |  Public IP: $PUBLIC_IP"
    echo "Net: $NET_STATE ($INTERFACE) | Connections: $CONN_COUNT"
    echo -e "Listening Ports: ${GREEN}$OPEN_PORTS${NO_COLOR}"

    if [ "$SSH_SESSIONS" -gt 0 ]; then
        echo -e "${RED}SECURITY ALERT: $SSH_SESSIONS active SSH session(s)!${NO_COLOR}"
    else
        echo -e "${GREEN}SSH Security: No external connections detected${NO_COLOR}"
    fi

    echo "----------------------------------------------------------"
    # RAM Monitor
    if [ $PERCENTAGE_RAM -ge 90 ]; then
        echo -e "${RED}RAM ALERT:${NO_COLOR} $(draw_bar $PERCENTAGE_RAM)"
        printf "${YELLOW}%-10s %-8s %-7s %-20s${NO_COLOR}\n" "USER" "PID" "%MEM" "COMMAND"
        ps aux --sort=-%mem | head -n4 | awk 'NR >1 {printf "%-10s %-8s %-7s %-20s\n" , $1, $2 , $4"%", substr($11,1,30)}'
    else
        echo -e "${GREEN}RAM OK:   ${NO_COLOR} $(draw_bar $PERCENTAGE_RAM)"
    fi

    # Disk Monitor
    if [ $DISK_USAGE -ge 80 ]; then
        echo -e "${RED}DISK ALERT:${NO_COLOR} $(draw_bar $DISK_USAGE)"
    else
        echo -e "${GREEN}DISK OK:   ${NO_COLOR} $(draw_bar $DISK_USAGE)"
    fi
    echo -e "${YELLOW}==========================================================${NO_COLOR}"

    # Crisis Snapshot logic
    if [ $PERCENTAGE_RAM -ge 90 ] || [ "$LOAD_VAL" -ge 5 ]; then
        {
            echo "=== CRISIS SNAPSHOT: $DATE ==="
            echo "Status: RAM ${PERCENTAGE_RAM}% | Load ${LOAD_CPU}"
            ps aux --sort=-%mem | head -n 6
            echo "-------------------------------------------"
        } >> "$LOG_FILE" 2>/dev/null || {
            echo "Snapshot: $DATE | Critical load detected" >> "./system_crisis.log"
        }
    fi

    sleep 2
done
