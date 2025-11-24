#!/bin/bash

# --- 1. CONFIG & COLORS ---
# Style Kuli-Korporat (Cyan & Bold)
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# --- 2. FUNGSI PERSIAPAN (Logic: Download Manual seperti Teddysun) ---
prepare_speedtest() {
    echo -e " ${YELLOW}[*] Preparing Speedtest Engine...${NC}"
    
    # Hapus sisa-sisa percobaan sebelumnya
    rm -rf speedtest_engine speedtest.tgz
    
    # Buat folder khusus (Isolasi biar gak bentrok sama system)
    mkdir -p speedtest_engine
    
    # Download Binary Versi 1.2.0 (Ini versi SAKTI yang dipakai Teddysun)
    # Kita wget diam-diam (-q)
    wget -q -O speedtest.tgz "https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-x86_64.tgz"
    
    # Extract ke folder khusus
    if [ -f speedtest.tgz ]; then
        tar -zxf speedtest.tgz -C speedtest_engine
        chmod +x speedtest_engine/speedtest
        rm speedtest.tgz
    else
        echo -e " ${RED}[!] Gagal download binary. Cek koneksi internet.${NC}"
        exit 1
    fi
}

# --- 3. FUNGSI TEST (Logic: JSON Parsing biar lebih akurat dari Teddysun) ---
# Teddysun baca text log, kita baca JSON biar bisa diwarnain dinamis
run_test() {
    local nodeName=$1
    local serverId=$2
    local args="--accept-license --accept-gdpr --format=json --progress=no"
    
    if [[ -n "$serverId" ]]; then
        args="$args --server-id=$serverId"
    fi

    # Eksekusi Binary di dalam folder
    output=$(./speedtest_engine/speedtest $args 2>/dev/null)

    # Parsing Hasil (Menggunakan grep & awk karena JSON string)
    if [[ -n "$output" ]] && [[ $output != *"error"* ]]; then
        # Ambil Ping
        ping=$(echo "$output" | grep -oP '"latency":\s*\K[0-9.]+' | head -1)
        # Ambil Speed (Bytes)
        dl_raw=$(echo "$output" | grep -oP '"download":{"bandwidth":\s*\K[0-9]+' | head -1)
        ul_raw=$(echo "$output" | grep -oP '"upload":{"bandwidth":\s*\K[0-9]+' | head -1)
        
        # Konversi ke Mbps (Rumus: bytes * 8 / 1000000)
        dl_mbps=$(awk "BEGIN {printf \"%.2f\", $dl_raw * 8 / 1000000}")
        ul_mbps=$(awk "BEGIN {printf \"%.2f\", $ul_raw * 8 / 1000000}")
        
        # Cetak Baris Tabel
        printf " ${CYAN}%-18s${NC} ${GREEN}%-15s${NC} ${RED}%-15s${NC} ${YELLOW}%-15s${NC}\n" "$nodeName" "${ul_mbps} Mbps" "${dl_mbps} Mbps" "${ping} ms"
    else
        printf " ${CYAN}%-18s${NC} ${RED}%-15s${NC} ${RED}%-15s${NC} ${RED}%-15s${NC}\n" "$nodeName" "Fail" "Fail" "Timeout"
    fi
}

# --- 4. MAIN PROGRAM START ---
clear

# Header Kuli
echo -e "${CYAN}"
echo " _   __      _ _      "
echo "| | / /     | (_)     "
echo "| |/ / _   _| |_      "
echo "|    \| | | | | |     "
echo "| |\  \ |_| | | |     "
echo "\_| \_/\__,_|_|_|     "
echo -e "${NC}"
echo "------------------------------------------------------------------"
echo -e " Script By          : Kuli-Korporat (Original Logic)"
echo -e " Version            : ${GREEN}v2025-11-24 (Learned from Teddysun)${NC}"
echo "------------------------------------------------------------------"

# System Info (Singkat Padat)
cname=$(awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo | head -1 | sed 's/^[ \t]*//')
cores=$(nproc)
os=$(grep -oP '(?<=^PRETTY_NAME=).+' /etc/os-release | tr -d '"')
disk=$(df -h / | awk '/\// {print $2 " Total / " $3 " Used"}')
mem=$(free -h | awk '/^Mem:/ {print $2 " Total / " $3 " Used"}')

echo -e " CPU Model          : $cname"
echo -e " CPU Cores          : $cores Cores"
echo -e " OS System          : $os"
echo -e " Disk Usage         : $disk"
echo -e " RAM Usage          : $mem"
echo "------------------------------------------------------------------"

# Prepare Alat
prepare_speedtest
echo "------------------------------------------------------------------"

# Print Table Header
printf "%-18s %-15s %-15s %-15s\n" " Node Name" "Upload" "Download" "Latency"
echo "------------------------------------------------------------------"

# Jalankan Test (Daftar Server Pilihan)
run_test "Speedtest.net" ""          # Auto
run_test "Jakarta" "11116"           # First Media (Sering Stabil)
run_test "Singapore" "13623"         # Singtel
run_test "Tokyo, JP" "15047"         # IPA CyberLab
run_test "Los Angeles" "17381"       # HiFormance

# Cleanup (Hapus jejak seperti profesional)
rm -rf speedtest_engine speedtest.tgz

echo "------------------------------------------------------------------"
echo -e " Done."
