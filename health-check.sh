esto #!/bin/bash

USER=$(whoami)
DATE=$(date +%H:%M)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NO_COLOR='\033[0m'

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
	LOAD_CPU=$(cat /proc/loadavg |awk '{print $1, $2, $3}')

	TOTAL_PROC=$(ps aux | wc -l | awk '{print $1 - 1}')
	ZOMBIES=$(ps aux |awk '$8=="Z"' | wc -l)
	STOPPED_PROC=$(ps axo state | grep -c "T")
	SLEEP_PROC=$(ps axo state | grep -c "S")


	TOTAL_RAM=$(free -m| grep Mem | awk '{print $2}')
	USED_RAM=$(free -m| grep Mem | awk '{print $3}')

	TOTAL_SWAP=$(free -m | grep Swap | awk '{print $2}')
	USED_SWAP=$(free -m | grep Swap | awk '{print $3}')

	DISK_USAGE=$(df / --output=pcent | grep -oP '\d+' |head -n1)

	PERCENTAGE_RAM=$((USED_RAM*100/TOTAL_RAM))
	PERCENTAGE_SWAP=$((USED_SWAP*100/TOTAL_SWAP))

	INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
	NET_STATE=$(cat /sys/class/net/$INTERFACE/operstate)
        CONN_COUNT=$(ss -tun | grep -c "ESTAB")
	LOCAL_IP=$(hostname -I | awk '{print $1}')

	echo -e "${YELLOW}==========================================================${NO_COLOR}"
	echo -e " HEALTH REPORT - $DATE"
	echo -e "${YELLOW}==========================================================${NO_COLOR}"
	echo "Usuario: $USER    System: $(hostname)"
	echo "Uptime: $UPTIME_SYSTEM"
	echo -e "CPU LOAD (1, 5, 15 min): $LOAD_CPU  |Total Process $TOTAL_PROC  |${RED} Zoombie Process: $ZOMBIES ${NO_COLOR}| ${YELLOW} Stop Process: $STOPPED_PROC ${NO_COLOR}  |${YELLOW} Sleep Process: $SLEEP_PROC ${NO_COLOR} " 
	echo "Active sessions: $ACTIVE_SESSION_COUNT "
	echo "Local IP: $LOCAL_IP  |  Public IP: $PUBLIC_IP"
	echo "Net: $NET_STATE ($INTERFACE) | Connections : $CONN_COUNT"

	if [ $PERCENTAGE_RAM -ge 90 ]; then
		echo -e "${RED}ALERT: $(draw_bar $PERCENTAGE_RAM) {NO_COLOR}"
		echo "--------------------------------------------------------"
		printf "${YELLOW}%-10s %-8s %-7s %-20s${NO_COLOR}\n" "USER" "PID" "%MEM" "COMMAND"

		ps aux	--sort=-%mem | head -n4 |awk 'NR >1 {printf "%-10s %-8s %-7s %-20s\n" , $1, $2 , $4"%", substr($11,1,30)}'
	else
		echo -e "${GREEN}RAM OK: $(draw_bar $PERCENTAGE_RAM)  ${NO_COLOR}"
	fi

	if [ $PERCENTAGE_SWAP -gt 0 ]; then
		echo -e "${RED}ALERT SWAP is in use: $PERCENTAGE_SWAP% ${NO_COLOR}"
	else
		echo -e "${GREEN}NO SWAP USAGE ${NO_COLOR}"
	fi

	if [ -z "$DISK_USAGE" ]; then
		echo -e "${RED}ERROR: Disk information not found"

	else
		if [ $DISK_USAGE -ge 80 ]; then
			echo -e "${RED}ALERT: Disk is almost full: ${NO_COLOR} $(draw_bar $DISK_USAGE)"
		else
			echo -e "${GREEN}DISK OK:$ {NO_COLOR} $(draw_bar $DISK_USAGE)"
		fi
	fi
	echo -e "${YELLOW}==========================================================${NO_COLOR}"
	sleep 2
done

