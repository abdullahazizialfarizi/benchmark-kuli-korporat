#!/bin/bash

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# --- Clear Screen & Header ---
clear
echo -e "${CYAN}"
echo " _   __      _ _      "
echo "| | / /     | (_)     "
echo "| |/ / _   _| |_      "
echo "|    \| | | | | |     "
echo "| |\  \ |_| | | |     "
echo "\_| \_/\__,_|_|_|     "
echo -e "${NC}"
echo -e " SERVER BENCHMARK V6.0 (Complete)"
echo -e " https://github.com/abdullahazizialfarizi"
echo "------------------------------------------------------------------"

# --- 1. SYSTEM INFORMATION ---
if [ -f /etc/os-release ]; then
    OS_NAME=$(grep -oP '(?<=^PRETTY_NAME=).+' /etc/os-release | tr -d '"')
else
    OS_NAME=$(uname -o)
fi

KERNEL=$(uname -r)
HOSTNAME=$(hostname)
CPU_MODEL=$(awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo | head -1 | sed 's/^[ \t]*//')
CPU_CORES=$(awk -F: '/model name/ {core++} END {print core}' /proc/cpuinfo)
UPTIME=$(uptime -p)

# Detect ISP & Location (Penting buat analisis latency)
ISP_INFO=$(curl -s http://ip-api.com/json)
ISP_ORG=$(echo $ISP_INFO | grep -oP '(?<="isp":")[^"]*' || echo "Unknown")
ISP_LOC=$(echo $ISP_INFO | grep -oP '(?<="country":")[^"]*' || echo "Unknown")
ISP_CITY=$(echo $ISP_INFO | grep -oP '(?<="city":")[^"]*' || echo "Unknown")

printf " ${CYAN}%-15s${NC} : %s\n" "Hostname" "$HOSTNAME"
printf " ${CYAN}%-15s${NC} : %s\n" "OS System" "$OS_NAME"
printf " ${CYAN}%-15s${NC} : %s\n" "Kernel" "$KERNEL"
printf " ${CYAN}%-15s${NC} : %s\n" "Uptime" "$UPTIME"
printf " ${CYAN}%-15s${NC} : %s\n" "CPU Model" "$CPU_MODEL"
printf " ${CYAN}%-15s${NC} : %s Cores\n" "CPU Cores" "$CPU_CORES"
printf " ${CYAN}%-15s${NC} : %s\n" "ISP / Org" "$ISP_ORG"
printf " ${CYAN}%-15s${NC} : %s, %s\n" "Location" "$ISP_CITY" "$ISP_LOC"
echo "------------------------------------------------------------------"

# --- 2. DISK I/O TEST ---
echo -e " ${GREEN}[ Testing Disk Speed ]${NC}"
for i in {1..3}; do
    SPEED=$( (dd if=/dev/zero of=test_$$ bs=64k count=16k conv=fdatasync && rm -f test_$$) 2>&1 | awk -F, '{io=$NF} END { print io}' | sed 's/^[ \t]*//' )
    printf " ${CYAN}%-15s${NC} : %s\n" "I/O Speed #$i" "$SPEED"
done
echo "------------------------------------------------------------------"

# --- 3. NETWORK SPEEDTEST (OFFICIAL BINARY) ---
echo -e " ${GREEN}[ Testing Network Speed ]${NC}"

# Download Official Speedtest Binary (Linux x86_64) if not exists
if [ ! -f "speedtest" ]; then
    wget -q -O speedtest.tgz https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-x86_64.tgz
    tar -zxf speedtest.tgz speedtest
    chmod +x speedtest
fi

printf "\n%-18s %-15s %-15s %-15s\n" " Node Name" "Upload" "Download" "Latency"
echo "-------------------------------------------------------------"

run_test() {
    local name=$1
    local id=$2
    local cmd="./speedtest --accept-license --accept-gdpr --format=json"
    
    if [[ -n "$id" ]]; then
        cmd="$cmd -s $id"
    fi

    output=$(eval $cmd 2>/dev/null)
    
    if [[ -n "$output" ]]; then
        ping=$(echo "$output" | grep -oP '"latency":\s*\K[0-9.]+' | head -1)
        dl_raw=$(echo "$output" | grep -oP '"download":{"bandwidth":\s*\K[0-9]+' | head -1)
        ul_raw=$(echo "$output" | grep -oP '"upload":{"bandwidth":\s*\K[0-9]+' | head -1)
        
        # Kalkulasi Mbps
        dl_calc=$(awk "BEGIN {printf \"%.2f\", $dl_raw * 8 / 1000000}")
        ul_calc=$(awk "BEGIN {printf \"%.2f\", $ul_raw * 8 / 1000000}")
        
        printf " %-18s %-15s %-15s %-15s\n" "$name" "$ul_calc Mbps" "$dl_calc Mbps" "$ping ms"
    else
        printf " %-18s %-15s %-15s %-15s\n" "$name" "Fail" "Fail" "Timeout"
    fi
}

# 1. Test Auto (Lokal)
run_test "Closest/Auto" ""

# 2. Test Internasional
run_test "Singapore" "13623"
run_test "Tokyo, JP" "15047"
run_test "Los Angeles, US" "17381"

# Cleanup
rm speedtest speedtest.tgz speedtest.md speedtest.5 2>/dev/null

echo "------------------------------------------------------------------"
echo -e " Done."
echo ""
