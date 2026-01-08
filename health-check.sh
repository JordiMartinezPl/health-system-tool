#!/bin/bash


#clean
clear
# --- CONFIGURATION & COLORS ---
USER=$(whoami)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NO_COLOR='\033[0m'

# LOGGING
LOG_FILE="/var/log/system_crisis.log"
LOCAL_LOG="./system_crisis.log"

# --- INITIAL STATES --
INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
PREV_NET_STATE=$(cat /sys/class/net/$INTERFACE/operstate 2>/dev/null || echo "down")
PREV_SSH_COUNT=$(ss -tun | grep -c ":22")
PREV_RAM_STATE="OK"
CORES=$(nproc)

# --- CURSOR CONTROL ---
# Hide cursor for a professional look
printf "\033[?25l"

# --- HELP MENU ---
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    printf "\033[?25h" # Show cursor before exiting
    echo -e "${YELLOW}Health System Tool v1.1${NO_COLOR}"
    echo "Usage: ./health-check.sh"
    echo ""
    echo "Description: Real-time monitor for CPU, RAM, Disk, and Network."
    exit 0
fi

# --- DEPENDENCY CHECK ---
for cmd in curl awk ss ps free df hostname bc top; do
    if ! command -v $cmd &> /dev/null; then
        printf "\033[?25h"
        echo -e "${RED}Error: Required command '$cmd' is not installed.${NO_COLOR}"
        exit 1
    fi
done

# --- CLEAN EXIT ---
clean_exit(){
    # Show cursor again when stopping
    printf "\033[?25h"
    clear
    echo -e "${NO_COLOR}\n[!] Monitor stopped by user. Cleaning up..."
    exit 0
}
trap clean_exit SIGINT SIGTERM

log_event(){
    local message=$1
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] EVENT: $message" >> "$LOG_FILE" 2>/dev/null || \
    echo "[$timestamp] EVENT: $message" >> "$LOCAL_LOG"
}

# --- INITIAL DATA ---
PUBLIC_IP=$(curl -s --max-time 2 ifconfig.me)
[ -z "$PUBLIC_IP" ] && PUBLIC_IP="Unknown net"

draw_bar(){
    local percentage=$1
    local width=20
    # Cap percentage at 100 for visual bar
    local display_perc=$percentage
    [ $display_perc -gt 100 ] && display_perc=100
    
    local filled=$((display_perc * width / 100))
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
    # Use ANSI code to move cursor to top-left (no flicker)
    printf "\033[H"

    # --- DATA GATHERING ---
    DATE=$(date +%D" "%H:%M:%S)
    UPTIME_SYSTEM=$(uptime -p)
    ACTIVE_SESSION_COUNT=$(who | wc -l)

    # CPU & Load Analytics
    LOAD_CPU=$(cat /proc/loadavg | awk '{print $1, $2, $3}')
    LOAD_1M=$(echo $LOAD_CPU | awk '{print $1}')
    # Saturation: (Load / Cores) * 100
    CPU_SAT=$(echo "scale=0; ($LOAD_1M * 100) / $CORES" | bc 2>/dev/null)
    # I/O Wait (Disk Latency)
    IO_WAIT=$(top -bn1 | grep "Cpu(s)" | awk '{print $10}' | tr ',' '.')

    # File Descriptors
    FILE_INFO=$(cat /proc/sys/fs/file-nr)
    FILES_OPEN=$(echo $FILE_INFO | awk '{print $1}')
    FILES_MAX=$(echo $FILE_INFO | awk '{print $3}')
    FILES_PERC=$(( FILES_OPEN * 100 / FILES_MAX ))

    # Processes
    TOTAL_PROC=$(ps aux | wc -l | awk '{print $1 - 1}')
    ZOMBIES=$(ps aux | awk '$8=="Z"' | wc -l)
    STOPPED_PROC=$(ps axo state | grep -c "T")
    SLEEP_PROC=$(ps axo state | grep -c "S")

    # RAM & Disk
    TOTAL_RAM=$(free -m | grep Mem | awk '{print $2}')
    USED_RAM=$(free -m | grep Mem | awk '{print $3}')
    PERCENTAGE_RAM=$((USED_RAM*100/TOTAL_RAM))
    DISK_USAGE=$(df / --output=pcent | grep -oP '\d+' | head -n1)

    # Network & Security
    NET_STATE=$(cat /sys/class/net/$INTERFACE/operstate 2>/dev/null || echo "down")
    CONN_COUNT=$(ss -tun | grep -c "ESTAB")
    LOCAL_IP=$(hostname -I | awk '{print $1}')
    OPEN_PORTS=$(ss -tuln | grep LISTEN | awk '{print $5}' | cut -d':' -f2 | sort -u | tr '\n' ' ')
    SSH_SESSIONS=$(ss -tun | grep -c ":22")

    # --- DASHBOARD OUTPUT ---
    echo -e "${YELLOW}==========================================================${NO_COLOR}"
    echo -e " PRO SYS-ADMIN MONITOR - $DATE"
    echo -e "${YELLOW}==========================================================${NO_COLOR}"
    echo -e "User: $USER | Host: $(hostname) | Cores: $CORES"
    echo -e "Uptime: $UPTIME_SYSTEM"
    echo -e "CPU Load: $LOAD_CPU"
    echo -e "CPU Saturation: $(draw_bar $CPU_SAT) | I/O Wait: ${RED}${IO_WAIT}%${NO_COLOR}"
    echo -e "File Handlers:  $(draw_bar $FILES_PERC) ($FILES_OPEN/$FILES_MAX)"
    echo -e "Total Proc: $TOTAL_PROC | Zombies: $ZOMBIES | Stopped: $STOPPED_PROC  | Sleeping: $SLEEP_PROC"
    echo "----------------------------------------------------------"
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

    # --- LOGGING LOGIC ---
    # Crisis Snapshot
    if [ $PERCENTAGE_RAM -ge 90 ] || [ $CPU_SAT -ge 100 ]; then
        {
            echo "=== CRISIS SNAPSHOT: $DATE ==="
            echo "RAM: ${PERCENTAGE_RAM}% | Saturation: ${CPU_SAT}% | I/O Wait: ${IO_WAIT}%"
            ps aux --sort=-%mem | head -n 6
            echo "-------------------------------------------"
        } >> "$LOG_FILE" 2>/dev/null || {
            echo "=== CRISIS SNAPSHOT: $DATE ===" >> "$LOCAL_LOG"
            ps aux --sort=-%mem | head -n 6 >> "$LOCAL_LOG"
        }
    fi

    # Network Events
    if [ "$NET_STATE" != "$PREV_NET_STATE" ]; then
        log_event "Network interface $INTERFACE changed from '$PREV_NET_STATE' to '$NET_STATE'"
        PREV_NET_STATE=$NET_STATE
    fi

    # Security Events
    if [ "$SSH_SESSIONS" -ne "$PREV_SSH_COUNT" ]; then
        log_event "SSH sessions changed: $PREV_SSH_COUNT -> $SSH_SESSIONS"
        PREV_SSH_COUNT=$SSH_SESSIONS
    fi

    # RAM State Transitions
    CURRENT_RAM_STATE="OK"
    [ $PERCENTAGE_RAM -ge 90 ] && CURRENT_RAM_STATE="CRITICAL"
    if [ "$CURRENT_RAM_STATE" != "$PREV_RAM_STATE" ]; then
        log_event "System Health: RAM moved to $CURRENT_RAM_STATE state ($PERCENTAGE_RAM%)"
        PREV_RAM_STATE=$CURRENT_RAM_STATE
    fi

    sleep 2
done