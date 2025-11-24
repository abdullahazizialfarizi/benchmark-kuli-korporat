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
echo -e " SERVER BENCHMARK V4.0 (Auto-Fix)"
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

printf " ${CYAN}%-15s${NC} : %s\n" "Hostname" "$HOSTNAME"
printf " ${CYAN}%-15s${NC} : %s\n" "OS System" "$OS_NAME"
printf " ${CYAN}%-15s${NC} : %s\n" "Kernel" "$KERNEL"
printf " ${CYAN}%-15s${NC} : %s\n" "Uptime" "$UPTIME"
printf " ${CYAN}%-15s${NC} : %s\n" "CPU Model" "$CPU_MODEL"
printf " ${CYAN}%-15s${NC} : %s Cores\n" "CPU Cores" "$CPU_CORES"
echo "------------------------------------------------------------------"

# --- 2. DISK I/O TEST ---
echo -e " ${GREEN}[ Testing Disk Speed ]${NC}"
for i in {1..3}; do
    SPEED=$( (dd if=/dev/zero of=test_$$ bs=64k count=16k conv=fdatasync && rm -f test_$$) 2>&1 | awk -F, '{io=$NF} END { print io}' | sed 's/^[ \t]*//' )
    printf " ${CYAN}%-15s${NC} : %s\n" "I/O Speed #$i" "$SPEED"
done
echo "------------------------------------------------------------------"

# --- 3. NETWORK SPEEDTEST ---
echo -e " ${GREEN}[ Testing Network Speed ]${NC}"

# Install Python3 jika belum ada
if ! command -v python3 &> /dev/null; then
    echo " Installing Python3..."
    apt-get update -q && apt-get install -y python3 -q
fi

# Download script speedtest
curl -s -L -o speedtest-cli https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py
chmod +x speedtest-cli

printf "\n%-18s %-15s %-15s %-15s\n" " Node Name" "Upload" "Download" "Latency"
echo "-------------------------------------------------------------"

run_test() {
    local name=$1
    local args=$2
    
    # Run speedtest (tambah --secure untuk fix ssl issue)
    result=$(./speedtest-cli $args --secure --simple 2>/dev/null)
    
    if [[ -n "$result" ]]; then
        ping=$(echo "$result" | awk '/Ping/ {print $2 " ms"}')
        dl=$(echo "$result" | awk '/Download/ {print $2 " Mbps"}')
        ul=$(echo "$result" | awk '/Upload/ {print $2 " Mbps"}')
        printf " %-18s %-15s %-15s %-15s\n" "$name" "$ul" "$dl" "$ping"
    else
         # Jika gagal, coba print error debug ke file terpisah
         printf " %-18s %-15s %-15s %-15s\n" "$name" "Fail" "Fail" "Timeout"
    fi
}

# 1. Test Server Terdekat (Otomatis) - Paling akurat
run_test "Closest/Auto" ""

# 2. Test Server Spesifik (Jika ini fail, berarti servernya down/blokir)
# Singapore (Singtel)
run_test "Singapore" "--server 13623"
# US (Los Angeles)
run_test "USA (LA)" "--server 17381"

rm speedtest-cli
echo "------------------------------------------------------------------"
echo -e " Done."
echo ""
