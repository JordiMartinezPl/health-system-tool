#!/bin/bash
export LC_ALL=C 

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NO_COLOR='\033[0m'


LOG_DIR="/var/log"
LOG_FILE="$LOG_DIR/system_crisis.log"

CORES=$(nproc 2>/dev/null || echo 1)
printf "\033[?25l" 

log_event(){
    local message=$1
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] ALERT: $message" >> "$LOG_FILE" 2>/dev/null || \
    echo "[$timestamp] ALERT: $message" >> "./system_crisis.log" 2>/dev/null
}

clean_exit(){
    printf "\033[?25h" 
    reset
    exit 0
}
trap clean_exit SIGINT SIGTERM

draw_bar(){
    local percentage=${1:-0}
    percentage=$(printf "%.0f" "$percentage" 2>/dev/null || echo 0)
    [ "$percentage" -gt 100 ] && percentage=100
    local width=20
    local filled=$((percentage * width / 100))
    local empty=$((width - filled))
    local COLOR=$GREEN
    [ "$percentage" -ge 70 ] && COLOR=$YELLOW
    [ "$percentage" -ge 90 ] && COLOR=$RED
    
    local bar="["
    bar+="${COLOR}"
    for ((i=0; i<filled; i++)); do bar+="#"; done
    bar+="${NO_COLOR}"
    for ((i=0; i<empty; i++)); do bar+="-"; done
    bar+="] ${percentage}%"
    
    echo -e "$bar"
}

PUBLIC_IP=$(curl -s --max-time 2 ifconfig.me || echo "N/A")

while true; do
    RAM_P=$(free -m 2>/dev/null | awk '/Mem:/ {if($2>0) printf "%.0f", ($3/$2)*100; else print 0}')
    LOAD_AVG=$(cat /proc/loadavg 2>/dev/null | awk '{print $1}')
    CPU_S=$(awk -v c="$CORES" -v l="$LOAD_AVG" 'BEGIN {printf "%.0f", (l*100)/c}')
    IO_W=$(top -bn1 2>/dev/null | grep -i "cpu" | sed 's/,/ /g' | awk '{for(i=1;i<=NF;i++) if($i ~ /wa/ || $i ~ /iow/) {print $(i-1); exit}}' | tr -d 'a-zA-Z% ')
    [ -z "$IO_W" ] && IO_W=0
    DISK_P=$(df / 2>/dev/null | awk 'NR>1 {for(i=1;i<=NF;i++) if($i ~ /%/) {print $i; exit}}' | tr -d '%')
    PROCESS_LIST=$(ps -axco state 2>/dev/null || ps -o state 2>/dev/null || ps ax -o state 2>/dev/null)
    
    TOTAL_PROC=$(echo "$PROCESS_LIST" | wc -l)
    RUNNING_PROC=$(echo "$PROCESS_LIST" | grep -c "R")
    SLEEPING_PROC=$(echo "$PROCESS_LIST" | grep -c "S")
    STOPPED_PROC=$(echo "$PROCESS_LIST" | grep -E -c "T|D") 
    ZOMBIES_PROC=$(echo "$PROCESS_LIST" | grep -c "Z")

    LOCAL_IP=$(ip -4 addr show scope global | awk '/inet / {print $2}' | cut -d/ -f1 | head -n1)
    [ -z "$LOCAL_IP" ] && LOCAL_IP="127.0.0.1"

    if command -v ss >/dev/null 2>&1; then
        SSH_S=$(ss -tun | grep -c ":22")
    elif command -v netstat >/dev/null 2>&1; then
        SSH_S=$(netstat -tun | grep -c ":22")
    else
        SSH_S=0
    fi
    SSH_S=${SSH_S:-0}

    DASH="${YELLOW}==========================================================${NO_COLOR}\n"
    DASH+=" GENERAL MONITOR - $(date "+%Y-%m-%d %H:%M:%S")\n"
    DASH+="${YELLOW}==========================================================${NO_COLOR}\n"
    DASH+="Host: $(hostname) | Cores: $CORES | Uptime: $(uptime 2>/dev/null | sed 's/.*up \([^,]*\), .*/\1/')\n"
    DASH+="CPU Saturation: $(draw_bar "$CPU_S") | I/O Wait: ${RED}${IO_W}%${NO_COLOR}\n"
    DASH+="RAM Usage:      $(draw_bar "$RAM_P")\n"
    DASH+="Disk Usage:     $(draw_bar "$DISK_P")\n"
    DASH+="----------------------------------------------------------\n"
    DASH+=" Processes: $TOTAL_PROC | Running: ${GREEN}$RUNNING_PROC${NO_COLOR} | Sleeping: $SLEEPING_PROC\n"
    DASH+=" Stopped: ${YELLOW}$STOPPED_PROC${NO_COLOR}   | Zombies: ${RED}$ZOMBIES_PROC${NO_COLOR}\n"
    DASH+="----------------------------------------------------------\n"
    DASH+=" Local IP: $LOCAL_IP | Public IP: $PUBLIC_IP\n"
    DASH+=" SSH Sessions: $SSH_S\n"
    DASH+="${YELLOW}==========================================================${NO_COLOR}"
    printf "\033[H\033[J%b\n" "$DASH"

    [ "$CPU_S" -ge 90 ] && log_event "Critical CPU Load: $CPU_S%"
    [ "$RAM_P" -ge 90 ] && log_event "Critical RAM Usage: $RAM_P%"
    [ "$ZOMBIES_PROC" -gt 0 ] && log_event "Zombie processes detected: $ZOMBIES_PROC"
    sleep 2
done