#!/bin/bash

# --- Colors & Styling ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PLAIN='\033[0m'
BOLD='\033[1m'

# --- Install Dependencies (Silent) ---
if [ ! -f "speedtest" ]; then
    wget -q -O speedtest.tgz https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-x86_64.tgz
    tar -zxf speedtest.tgz speedtest
    chmod +x speedtest
    rm speedtest.tgz speedtest.md speedtest.5 2>/dev/null
fi

clear

# Fungsi Garis
next() {
    printf "%-72s\n" "-" | sed 's/ /-/g'
}

# --- HEADER (Branding Kuli) ---
next
echo -e " ${BOLD}SERVER BENCHMARK V8.0 (ATM Enhanced)${PLAIN}"
echo -e " Script by          : Kuli-Korporat"
echo -e " GitHub             : github.com/abdullahazizialfarizi"
next

# --- 1. SYSTEM INFO (Bagian Amati & Tiru) ---
# Mengambil info dasar seperti script referensi tapi dirapikan

cname=$( awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
cores=$( awk -F: '/model name/ {core++} END {print core}' /proc/cpuinfo )
freq=$( awk -F: ' /cpu MHz/ {freq=$2} END {print freq}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
cache=$( awk -F: ' /cache size/ {cache=$2} END {print cache}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
uptime=$(uptime -p | sed 's/up //')

if [ -f /etc/os-release ]; then
    os_name=$(grep -oP '(?<=^PRETTY_NAME=).+' /etc/os-release | tr -d '"')
else
    os_name=$(uname -o)
fi

# Detect Virtualization
virt_type=$(systemd-detect-virt 2>/dev/null || echo "Unknown")

# Detect ISP
isp_json=$(curl -s http://ip-api.com/json)
org=$(echo $isp_json | grep -oP '(?<="isp":")[^"]*' || echo "Unknown")
city=$(echo $isp_json | grep -oP '(?<="city":")[^"]*' || echo "Unknown")
country=$(echo $isp_json | grep -oP '(?<="countryCode":")[^"]*' || echo "Unknown")

echo -e " CPU Model          : ${CYAN}$cname${PLAIN}"
echo -e " CPU Cores          : ${CYAN}$cores Cores @ $freq MHz${PLAIN}"
echo -e " CPU Cache          : ${CYAN}$cache${PLAIN}"
echo -e " OS & Kernel        : ${CYAN}$os_name ($(uname -r))${PLAIN}"
echo -e " Virtualization     : ${CYAN}$virt_type${PLAIN}"
echo -e " System Uptime      : ${CYAN}$uptime${PLAIN}"
echo -e " ISP & Location     : ${CYAN}$org - $city, $country${PLAIN}"
next

# --- 2. PERFORMANCE TEST (Bagian Modifikasi) ---

# A. RAM Speed Test (Fitur Baru)
# Menulis file ke /dev/shm (RAM) untuk cek throughput memory
echo -e " ${BOLD}[ Memory & Disk Performance ]${PLAIN}"
ram_speed=$( (dd if=/dev/zero of=/dev/shm/test_ram bs=1M count=512 conv=fdatasync && rm -f /dev/shm/test_ram) 2>&1 | awk -F, '{io=$NF} END { print io}' | sed 's/^[ \t]*//' )
echo -e " RAM Write Speed    : ${YELLOW}$ram_speed${PLAIN} (Direct Memory Write)"

# B. Disk I/O Test (Standard)
disk_speed=$( (dd if=/dev/zero of=test_$$ bs=64k count=16k conv=fdatasync && rm -f test_$$) 2>&1 | awk -F, '{io=$NF} END { print io}' | sed 's/^[ \t]*//' )
echo -e " Disk I/O Speed     : ${YELLOW}$disk_speed${PLAIN} (Sequential)"
next

# --- 3. NETWORK TEST (Bagian Modifikasi - Lebih Detail) ---
echo -e " ${BOLD}[ Network Speed & Quality ]${PLAIN}"
# Menambah kolom Jitter dan Packet Loss
printf "%-16s %-12s %-12s %-10s %-8s %-6s\n" "Node Name" "Upload" "Download" "Latency" "Jitter" "Loss"
echo "------------------------------------------------------------------------"

run_speedtest() {
    local name=$1
    local id=$2
    local args="--accept-license --accept-gdpr --format=json"
    
    if [[ -n "$id" ]]; then args="$args -s $id"; fi

    # Eksekusi
    output=$(./speedtest $args 2>/dev/null)

    if [[ -n "$output" ]]; then
        # Parse Data
        ping=$(echo "$output" | grep -oP '"latency":\s*\K[0-9.]+' | head -1)
        jitter=$(echo "$output" | grep -oP '"jitter":\s*\K[0-9.]+' | head -1)
        loss=$(echo "$output" | grep -oP '"packetLoss":\s*\K[0-9.]+' | head -1)
        dl_raw=$(echo "$output" | grep -oP '"download":{"bandwidth":\s*\K[0-9]+' | head -1)
        ul_raw=$(echo "$output" | grep -oP '"upload":{"bandwidth":\s*\K[0-9]+' | head -1)

        # Hitung Mbps
        dl=$(awk "BEGIN {printf \"%.1f\", $dl_raw * 8 / 1000000}")
        ul=$(awk "BEGIN {printf \"%.1f\", $ul_raw * 8 / 1000000}")
        
        # Format Loss (0 jika kosong)
        [[ -z "$loss" ]] && loss="0.0"
        
        # --- Logic Pewarnaan (Modifikasi Cerdas) ---
        # Ping: Hijau < 50ms, Kuning < 150ms, Merah > 150ms
        if (( $(echo "$ping < 50" | bc -l) )); then p_col=$GREEN; elif (( $(echo "$ping < 150" | bc -l) )); then p_col=$YELLOW; else p_col=$RED; fi
        
        # Speed: Hijau > 100Mbps, Merah < 10Mbps
        if (( $(echo "$dl > 100" | bc -l) )); then dl_col=$GREEN; else dl_col=$CYAN; fi
        
        # Jitter: Hijau < 10ms (Stabil), Merah > 10ms (Tidak stabil)
        if (( $(echo "$jitter < 10" | bc -l) )); then j_col=$GREEN; else j_col=$RED; fi

        printf " %-16s ${GREEN}%-12s${PLAIN} ${dl_col}%-12s${PLAIN} ${p_col}%-10s${PLAIN} ${j_col}%-8s${PLAIN} %-6s\n" "$name" "$ul Mbps" "$dl Mbps" "$ping ms" "$jitter ms" "$loss%"
    else
        printf " %-16s ${RED}%-12s${PLAIN} ${RED}%-12s${PLAIN} ${RED}%-10s${PLAIN} ${RED}%-8s${PLAIN} %-6s\n" "$name" "Fail" "Fail" "Timeout" "-" "-"
    fi
}

# List Server Test
run_speedtest "Closest/Auto" ""
run_speedtest "Jakarta, ID" "11362"
run_speedtest "Singapore, SG" "13623"
run_speedtest "Tokyo, JP" "15047"
run_speedtest "Los Angeles" "17381"
# Tambah Eropa biar lengkap
run_speedtest "London, UK" "17770" 

# Cleanup
rm speedtest speedtest.tgz 2>/dev/null
echo "------------------------------------------------------------------------"
echo -e " Done."
echo ""
