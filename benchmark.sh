#!/bin/bash

# --- COLORS ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
SKYBLUE='\033[0;36m'
PLAIN='\033[0m'

# --- CLEANUP & PREP ---
rm -f speedtest.py
clear

# --- HEADER LOGO ---
echo -e "${SKYBLUE}"
echo " _   __      _ _      "
echo "| | / /     | (_)     "
echo "| |/ / _   _| |_      "
echo "|    \| | | | | |     "
echo "| |\  \ |_| | | |     "
echo "\_| \_/\__,_|_|_|     "
echo -e "${PLAIN}"

# --- FUNCTION: GARIS ---
next() {
    printf "%-70s\n" "-" | sed 's/ /-/g'
}

# --- HEADER INFO ---
next
echo -e " Script By          : Kuli-Korporat (Original Python Ver)"
echo -e " Version            : ${GREEN}v1.0-Stable${PLAIN}"
echo -e " Usage              : ${YELLOW}wget -qO- [url] | bash${PLAIN}"
next

# --- 1. SYSTEM INFO ---
# Gak perlu neko-neko, ambil yang pasti ada
cname=$( awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
cores=$( awk -F: '/model name/ {core++} END {print core}' /proc/cpuinfo )
freq=$( awk -F: ' /cpu MHz/ {freq=$2} END {print freq}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
cache=$( awk -F: ' /cache size/ {cache=$2} END {print cache}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )

# Disk & RAM
disk_total=$(df -h / | awk '/\// {print $2}')
disk_used=$(df -h / | awk '/\// {print $3" Used"}')
ram_total=$(free -h | awk '/^Mem:/ {print $2}')
ram_used=$(free -h | awk '/^Mem:/ {print $3" Used"}')
swap_total=$(free -h | awk '/^Swap:/ {print $2}')

# OS Info
uptime=$(uptime -p | sed 's/up //')
if [ -f /etc/os-release ]; then
    os_name=$(grep -oP '(?<=^PRETTY_NAME=).+' /etc/os-release | tr -d '"')
else
    os_name=$(uname -o)
fi
virt=$(systemd-detect-virt 2>/dev/null || echo "kvm")
tcp=$(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')

# Network Check
ipv4=$(curl -s -4 --connect-timeout 2 google.com >/dev/null && echo "${GREEN}✓ Online${PLAIN}" || echo "${RED}✗ Offline${PLAIN}")

# ISP Info
isp_json=$(curl -s http://ip-api.com/json)
org=$(echo $isp_json | grep -oP '(?<="isp":")[^"]*' || echo "Unknown")
city=$(echo $isp_json | grep -oP '(?<="city":")[^"]*' || echo "Unknown")
country=$(echo $isp_json | grep -oP '(?<="countryCode":")[^"]*' || echo "Unknown")

# --- PRINT INFO ---
echo -e " CPU Model          : ${SKYBLUE}$cname${PLAIN}"
echo -e " CPU Cores          : ${SKYBLUE}$cores @ $freq MHz${PLAIN}"
echo -e " CPU Cache          : ${SKYBLUE}$cache${PLAIN}"
echo -e " Total Disk         : ${SKYBLUE}$disk_total ($disk_used)${PLAIN}"
echo -e " Total Mem          : ${SKYBLUE}$ram_total ($ram_used)${PLAIN}"
echo -e " Total Swap         : ${SKYBLUE}$swap_total${PLAIN}"
echo -e " System uptime      : ${SKYBLUE}$uptime${PLAIN}"
echo -e " OS                 : ${SKYBLUE}$os_name${PLAIN}"
echo -e " Arch               : ${SKYBLUE}$(uname -m) (64 Bit)${PLAIN}"
echo -e " Kernel             : ${SKYBLUE}$(uname -r)${PLAIN}"
echo -e " TCP CC             : ${SKYBLUE}$tcp${PLAIN}"
echo -e " Virtualization     : ${SKYBLUE}$virt${PLAIN}"
echo -e " IPv4 Connectivity  : $ipv4"
echo -e " Organization       : ${SKYBLUE}$org${PLAIN}"
echo -e " Location           : ${SKYBLUE}$city / $country${PLAIN}"
next

# --- 2. DISK I/O TEST ---
# Simple DD Test
io1=$( (dd if=/dev/zero of=test_$$ bs=64k count=16k conv=fdatasync && rm -f test_$$) 2>&1 | awk -F, '{io=$NF} END { print io}' | sed 's/^[ \t]*//' )
io2=$( (dd if=/dev/zero of=test_$$ bs=64k count=16k conv=fdatasync && rm -f test_$$) 2>&1 | awk -F, '{io=$NF} END { print io}' | sed 's/^[ \t]*//' )
io3=$( (dd if=/dev/zero of=test_$$ bs=64k count=16k conv=fdatasync && rm -f test_$$) 2>&1 | awk -F, '{io=$NF} END { print io}' | sed 's/^[ \t]*//' )

# Average Calc
v1=$(echo $io1 | awk '{print $1}')
v2=$(echo $io2 | awk '{print $1}')
v3=$(echo $io3 | awk '{print $1}')
avg=$(awk "BEGIN {printf \"%.1f\", ($v1 + $v2 + $v3) / 3}")
unit=$(echo $io1 | awk '{print $2}')

echo -e " I/O Speed(1st run) : ${YELLOW}$io1${PLAIN}"
echo -e " I/O Speed(2nd run) : ${YELLOW}$io2${PLAIN}"
echo -e " I/O Speed(3rd run) : ${YELLOW}$io3${PLAIN}"
echo -e " I/O Speed(average) : ${YELLOW}$avg $unit${PLAIN}"
next

# --- 3. NETWORK SPEEDTEST (PYTHON ENGINE) ---
# Download Engine
if ! command -v python3 &> /dev/null; then
    echo "Installing Python3..."
    apt-get update && apt-get install -y python3 >/dev/null 2>&1
fi
curl -s -L -o speedtest.py https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py
chmod +x speedtest.py

printf "%-18s %-15s %-15s %-15s\n" " Node Name" "Upload Speed" "Download Speed" "Latency"

# Fungsi Test
run_test() {
    local name=$1
    local id=$2
    
    if [[ -n "$id" ]]; then
        # Pakai Server ID
        output=$(python3 speedtest.py --server $id --simple 2>/dev/null)
    else
        # Auto
        output=$(python3 speedtest.py --simple 2>/dev/null)
    fi

    if [[ -n "$output" ]]; then
        ping=$(echo "$output" | awk '/Ping/ {print $2}')
        dl=$(echo "$output" | awk '/Download/ {print $2}')
        ul=$(echo "$output" | awk '/Upload/ {print $2}')
        
        # Format Output Table
        printf " ${YELLOW}%-18s${PLAIN} ${GREEN}%-15s${PLAIN} ${RED}%-15s${PLAIN} ${SKYBLUE}%-15s${PLAIN}\n" "$name" "$ul Mbps" "$dl Mbps" "$ping ms"
    else
        printf " ${YELLOW}%-18s${PLAIN} ${RED}%-15s${PLAIN} ${RED}%-15s${PLAIN} ${RED}%-15s${PLAIN}\n" "$name" "Fail" "Fail" "Timeout"
    fi
}

# List Server (ID Khusus Python Script - Beda dgn Ookla Apps)
run_test "Speedtest.net" ""
run_test "Jakarta" "11116"      # First Media
run_test "Singapore" "13623"    # Singtel
run_test "Tokyo, JP" "15047"
run_test "Los Angeles" "17381"

# Cleanup
rm speedtest.py

next
duration=$SECONDS
echo -e " Finished in        : $(($duration / 60)) min $(($duration % 60)) sec"
echo -e " Timestamp          : $(date '+%Y-%m-%d %H:%M:%S %Z')"
next
