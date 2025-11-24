#!/bin/bash
#
# KULI-KORPORAT SERVER
# Modern, Clean, Professional.
#

# --- 1. CONFIGURATION & COLORS ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Simbol Status
CHECK_MARK="${GREEN}✔${NC}"
CROSS_MARK="${RED}✘${NC}"
INFO_ICON="${CYAN}ℹ${NC}"

# Fungsi Garis Pemisah
draw_line() {
    printf "${BLUE}%*s${NC}\n" "${1:-70}" | tr ' ' '-'
}

# Fungsi Progress Bar (Untuk RAM/Swap)
draw_bar() {
    # $1 = Used, $2 = Total
    local used=$1
    local total=$2
    local percent=$(( 100 * used / total ))
    local bar_len=20
    local fill_len=$(( bar_len * percent / 100 ))
    local empty_len=$(( bar_len - fill_len ))

    # Warna bar berdasarkan persentase
    local color=$GREEN
    if [ $percent -ge 70 ]; then color=$YELLOW; fi
    if [ $percent -ge 90 ]; then color=$RED; fi

    printf "["
    printf "${color}%0.s|" $(seq 1 $fill_len)
    printf "${NC}%0.s." $(seq 1 $empty_len)
    printf "] ${percent}%%"
}

clear

# --- 2. HEADER ART ---
echo -e "${CYAN}"
echo " _  __     _ _      _  "
echo "| |/ /   _| (_)____| | __"
echo "| ' / | | | | |_  /| |/ /"
echo "| . \ |_| | | |/ / |   <   SERVER BENCHMARK V1.0"
echo "|_|\_\__,_|_|_/___||_|\_\  
echo -e "${NC}"
echo -e " ${WHITE}System Analysis & Network Performance Tool${NC}"
draw_line

# --- 3. SYSTEM TELEMETRY ---
echo -e "${WHITE} [ SYSTEM TELEMETRY ]${NC}"

# Get Data
os_name=$(grep -oP '(?<=^PRETTY_NAME=).+' /etc/os-release | tr -d '"')
kernel=$(uname -r)
uptime=$(uptime -p | sed 's/up //')
cpu_model=$(awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo | sed 's/^[ \t]*//')
cpu_cores=$(nproc)
load_avg=$(uptime | awk -F'load average:' '{ print $2 }' | sed 's/^[ \t]*//')

# RAM Calculation (in MB for bar)
mem_total_mb=$(free -m | awk '/^Mem:/ {print $2}')
mem_used_mb=$(free -m | awk '/^Mem:/ {print $3}')
swap_total_mb=$(free -m | awk '/^Swap:/ {print $2}')
swap_used_mb=$(free -m | awk '/^Swap:/ {print $3}')
# RAM String (Human readable)
mem_str=$(free -h | awk '/^Mem:/ {print $3 " / " $2}')
swap_str=$(free -h | awk '/^Swap:/ {print $3 " / " $2}')

# Print System Info
printf " ${CYAN}%-15s:${NC} %s\n" "OS System" "$os_name ($kernel)"
printf " ${CYAN}%-15s:${NC} %s\n" "Uptime" "$uptime"
printf " ${CYAN}%-15s:${NC} %s\n" "CPU Model" "$cpu_model"
printf " ${CYAN}%-15s:${NC} %s (Load: $load_avg)\n" "CPU Cores" "${cpu_cores} vCPU"
printf " ${CYAN}%-15s:${NC} %s " "RAM Usage" "$mem_str"
draw_bar $mem_used_mb $mem_total_mb
echo "" # Newline

# Handle Swap division by zero if swap is 0
if [ "$swap_total_mb" -gt 0 ]; then
    printf " ${CYAN}%-15s:${NC} %s " "Swap Usage" "$swap_str"
    draw_bar $swap_used_mb $swap_total_mb
    echo ""
else
    printf " ${CYAN}%-15s:${NC} 0B (No Swap Configured)\n" "Swap Usage"
fi
draw_line

# --- 4. STORAGE PERFORMANCE ---
echo -e "${WHITE} [ STORAGE I/O PERFORMANCE ]${NC}"
printf " ${INFO_ICON} Measuring sequential write speed (Avg of 3 runs)...\n"

run_dd() {
    (dd if=/dev/zero of=test_$$ bs=64k count=16k conv=fdatasync && rm -f test_$$) 2>&1 | awk -F, '{io=$NF} END { print io}' | sed 's/^[ \t]*//'
}

io1=$(run_dd)
io2=$(run_dd)
io3=$(run_dd)

# Layout 3 Kolom
printf " ${YELLOW}%-20s${NC} | ${YELLOW}%-20s${NC} | ${YELLOW}%-20s${NC}\n" "Run 1" "Run 2" "Run 3"
printf " %-20s | %-20s | %-20s\n" "$io1" "$io2" "$io3"
draw_line

# --- 5. NETWORK CONNECTIVITY ---
echo -e "${WHITE} [ NETWORK CONNECTIVITY ]${NC}"

# IP & ISP Info
isp_json=$(curl -s http://ip-api.com/json)
isp_org=$(echo $isp_json | grep -oP '(?<="isp":")[^"]*' || echo "N/A")
isp_loc=$(echo $isp_json | grep -oP '(?<="country":")[^"]*' || echo "N/A")
isp_ip=$(echo $isp_json | grep -oP '(?<="query":")[^"]*' || echo "N/A")

printf " ${CYAN}%-15s:${NC} %s\n" "ISP Provider" "$isp_org"
printf " ${CYAN}%-15s:${NC} %s\n" "Location" "$isp_loc"
printf " ${CYAN}%-15s:${NC} %s\n" "Public IP" "$isp_ip"
echo ""

# Speedtest Preparation
if ! command -v python3 &> /dev/null; then
    echo " Installing Python3 helper..."
    if [ -f /etc/debian_version ]; then apt-get update -q && apt-get install -y python3 -q >/dev/null 2>&1
    elif [ -f /etc/redhat-release ]; then yum install -y python3 -q >/dev/null 2>&1; fi
fi

curl -s -L -o speedtest-cli https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py
chmod +x speedtest-cli

printf " ${INFO_ICON} Running Speedtest on key nodes (ID, SG, JP)...\n\n"

# Header Table Network
printf "${BLUE}%-20s %-15s %-15s %-10s${NC}\n" "LOCATION" "UPLOAD" "DOWNLOAD" "PING"
printf "%-20s %-15s %-15s %-10s\n" "--------------------" "---------------" "---------------" "----------"

test_node() {
    local name=$1
    local id=$2
    output=$(./speedtest-cli --server $id --simple 2>/dev/null)
    
    if [[ -n "$output" ]]; then
        ping=$(echo "$output" | awk '/Ping/ {print $2}')
        dl=$(echo "$output" | awk '/Download/ {print $2}')
        ul=$(echo "$output" | awk '/Upload/ {print $2}')
        
        # Color coding for high speed
        dl_color=$NC
        if (( $(echo "$dl > 100" | bc -l 2>/dev/null) )); then dl_color=$GREEN; fi
        
        printf " %-19s ${YELLOW}%-15s${NC} ${dl_color}%-15s${NC} %-10s\n" "$name" "$ul Mbps" "$dl Mbps" "$ping ms"
    else
        printf " %-19s ${RED}%-15s${NC} ${RED}%-15s${NC} %-10s\n" "$name" "Fail" "Fail" "-"
    fi
}

# Node ID Selection
test_node "Jakarta, ID" "11362"
test_node "Singapore, SG" "13623"
test_node "Tokyo, JP" "15047"
test_node "Los Angeles, US" "17381"

rm speedtest-cli
echo ""
draw_line

# --- FOOTER ---
echo -e " ${WHITE}Benchmark Completed at $(date '+%H:%M:%S')${NC}"
echo -e " ${CYAN}Generated by kuli-korporat toolkit${NC}"
draw_line
echo ""
