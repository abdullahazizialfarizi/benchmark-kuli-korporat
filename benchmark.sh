#!/bin/bash

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- Clear Screen ---
clear

# --- ASCII ART HEADER ---
echo -e "${CYAN}"
echo " _   __      _ _      "
echo "| | / /     | (_)     "
echo "| |/ / _   _| |_      "
echo "|    \| | | | | |     "
echo "| |\  \ |_| | | |     "
echo "\_| \_/\__,_|_|_|     "
echo -e "${NC}"
echo -e " SERVER BENCHMARK V1.0"
echo -e " https://github.com/abdullahazizialfarizi"
echo "------------------------------------------------------------------"

# --- 1. SYSTEM INFORMATION ---
# Ambil Info OS
if [ -f /etc/os-release ]; then
    OS_NAME=$(grep -oP '(?<=^PRETTY_NAME=).+' /etc/os-release | tr -d '"')
else
    OS_NAME=$(uname -o)
fi

# Ambil Info Hardware
KERNEL=$(uname -r)
HOSTNAME=$(hostname)
CPU_MODEL=$(awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo | sed 's/^[ \t]*//')
CPU_CORES=$(awk -F: '/model name/ {core++} END {print core}' /proc/cpuinfo)
RAM_USED=$(free -h | awk '/^Mem:/ {print $3}')
RAM_TOTAL=$(free -h | awk '/^Mem:/ {print $2}')
SWAP_USED=$(free -h | awk '/^Swap:/ {print $3}')
SWAP_TOTAL=$(free -h | awk '/^Swap:/ {print $2}')
UPTIME=$(uptime -p)

# Tampilkan Info (Menggunakan printf agar rapih)
printf " ${CYAN}%-15s${NC} : %s\n" "Hostname" "$HOSTNAME"
printf " ${CYAN}%-15s${NC} : %s\n" "OS System" "$OS_NAME"
printf " ${CYAN}%-15s${NC} : %s\n" "Kernel" "$KERNEL"
printf " ${CYAN}%-15s${NC} : %s\n" "Uptime" "$UPTIME"
printf " ${CYAN}%-15s${NC} : %s\n" "CPU Model" "$CPU_MODEL"
printf " ${CYAN}%-15s${NC} : %s ($CPU_CORES Cores)\n" "CPU Cores" "$CPU_CORES"
printf " ${CYAN}%-15s${NC} : %s / %s\n" "RAM" "$RAM_USED" "$RAM_TOTAL"
printf " ${CYAN}%-15s${NC} : %s / %s\n" "SWAP" "$SWAP_USED" "$SWAP_TOTAL"
echo "------------------------------------------------------------------"

# --- 2. DISK I/O TEST ---
echo -e " ${GREEN}[ Testing Disk Speed ]${NC}"
# Loop 3x test
for i in {1..3}; do
    SPEED=$( (dd if=/dev/zero of=test_$$ bs=64k count=16k conv=fdatasync && rm -f test_$$) 2>&1 | awk -F, '{io=$NF} END { print io}' | sed 's/^[ \t]*//' )
    printf " ${CYAN}%-15s${NC} : %s\n" "I/O Speed #$i" "$SPEED"
done
echo "------------------------------------------------------------------"

# --- 3. NETWORK SPEEDTEST ---
echo -e " ${GREEN}[ Testing Network Speed ]${NC}"

# Install Python jika belum ada
if ! command -v python3 &> /dev/null; then
    echo " Installing Python3..."
    if [ -f /etc/debian_version ]; then apt-get update -q && apt-get install -y python3 -q
    elif [ -f /etc/redhat-release ]; then yum install -y python3 -q; fi
fi

# Download speedtest-cli
curl -s -L -o speedtest-cli https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py
chmod +x speedtest-cli

printf "\n%-18s %-15s %-15s %-15s\n" " Node Name" "Upload" "Download" "Latency"
echo "-------------------------------------------------------------"

run_test() {
    local name=$1
    local id=$2
    result=$(./speedtest-cli --server $id --simple 2>/dev/null)
    
    if [[ -n "$result" ]]; then
        ping=$(echo "$result" | awk '/Ping/ {print $2 " ms"}')
        dl=$(echo "$result" | awk '/Download/ {print $2 " Mbps"}')
        ul=$(echo "$result" | awk '/Upload/ {print $2 " Mbps"}')
        printf " %-18s %-15s %-15s %-15s\n" "$name" "$ul" "$dl" "$ping"
    else
         printf " %-18s %-15s %-15s %-15s\n" "$name" "Fail" "Fail" "Timeout"
    fi
}

# Daftar Server (ID, SG, JP)
run_test "Jakarta" "11362"
run_test "Singapore" "13623"
run_test "Tokyo" "15047"

# Hapus file sampah
rm speedtest-cli

echo "------------------------------------------------------------------"
echo -e " Done. $(date)"
echo ""
