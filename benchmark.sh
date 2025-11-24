#!/bin/bash

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
SKYBLUE='\033[0;36m'
BLUE='\033[0;34m'
PLAIN='\033[0m'

# --- Install Speedtest Official (Silent) ---
if [ ! -f "speedtest" ]; then
    wget -q -O speedtest.tgz https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-x86_64.tgz
    tar -zxf speedtest.tgz speedtest
    chmod +x speedtest
    rm speedtest.tgz speedtest.md speedtest.5 2>/dev/null
fi

clear

# Fungsi Garis Separator
next() {
    printf "%-70s\n" "-" | sed 's/ /-/g'
}

# --- HEADER (LOGO KULI + INFO) ---
# Ini gabungan logo Kuli dengan style header Teddysun
echo -e "${SKYBLUE}"
echo " _   __      _ _      "
echo "| | / /     | (_)     "
echo "| |/ / _   _| |_      "
echo "|    \| | | | | |     "
echo "| |\  \ |_| | | |     "
echo "\_| \_/\__,_|_|_|     "
echo -e "${PLAIN}"
next
echo -e " A Bench.sh Script By kuli-korporat"
echo -e " Version            : ${GREEN}v2025-11-24 (Final Hybrid)${PLAIN}"
echo -e " Usage              : ${RED}wget -qO- [url] | bash${PLAIN}"
next

# --- GATHER SYSTEM INFO ---
cname=$( awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
cores=$( awk -F: '/model name/ {core++} END {print core}' /proc/cpuinfo )
freq=$( awk -F: ' /cpu MHz/ {freq=$2} END {print freq}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
cache=$( awk -F: ' /cache size/ {cache=$2} END {print cache}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )

aes=$(grep -i aes /proc/cpuinfo)
[[ -n "$aes" ]] && aes_info="${GREEN}✓ Enabled${PLAIN}" || aes_info="${RED}✗ Disabled${PLAIN}"
virt_check=$(grep -E "vmx|svm" /proc/cpuinfo)
[[ -n "$virt_check" ]] && virt_info="${GREEN}✓ Enabled${PLAIN}" || virt_info="${RED}✗ Disabled${PLAIN}"

disk_total=$(df -h / | awk '/\// {print $2}')
disk_used=$(df -h / | awk '/\// {print $3" Used"}')
ram_total=$(free -h | awk '/^Mem:/ {print $2}')
ram_used=$(free -h | awk '/^Mem:/ {print $3" Used"}')
swap_total=$(free -h | awk '/^Swap:/ {print $2}')
swap_used=$(free -h | awk '/^Swap:/ {print $3" Used"}')

uptime=$(uptime -p | sed 's/up //')
load=$(uptime | awk -F'load average:' '{ print $2 }' | sed 's/^[ \t]*//')
if [ -f /etc/os-release ]; then
    os_name=$(grep -oP '(?<=^PRETTY_NAME=).+' /etc/os-release | tr -d '"')
else
    os_name=$(uname -o)
fi
arch=$(uname -m)
kernel=$(uname -r)
tcp_cc=$(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')
virt_type=$(systemd-detect-virt 2>/dev/null || echo "kvm")

ipv4=$(curl -s -4 --connect-timeout 2 google.com >/dev/null && echo "${GREEN}✓ Online${PLAIN}" || echo "${RED}✗ Offline${PLAIN}")
ipv6=$(curl -s -6 --connect-timeout 2 google.com >/dev/null && echo "${GREEN}✓ Online${PLAIN}" || echo "${RED}✗ Offline${PLAIN}")

isp_json=$(curl -s http://ip-api.com/json)
org=$(echo $isp_json | grep -oP '(?<="isp":")[^"]*' || echo "Unknown")
city=$(echo $isp_json | grep -oP '(?<="city":")[^"]*' || echo "Unknown")
country=$(echo $isp_json | grep -oP '(?<="countryCode":")[^"]*' || echo "Unknown")
region=$(echo $isp_json | grep -oP '(?<="regionName":")[^"]*' || echo "Unknown")

# --- PRINT SYSTEM INFO ---
echo -e " CPU Model          : ${SKYBLUE}$cname${PLAIN}"
echo -e " CPU Cores          : ${SKYBLUE}$cores @ $freq MHz${PLAIN}"
echo -e " CPU Cache          : ${SKYBLUE}$cache${PLAIN}"
echo -e " AES-NI             : $aes_info"
echo -e " VM-x/AMD-V         : $virt_info"
echo -e " Total Disk         : ${SKYBLUE}$disk_total ($disk_used)${PLAIN}"
echo -e " Total Mem          : ${SKYBLUE}$ram_total ($ram_used)${PLAIN}"
echo -e " Total Swap         : ${SKYBLUE}$swap_total ($swap_used)${PLAIN}"
echo -e " System uptime      : ${SKYBLUE}$uptime${PLAIN}"
echo -e " Load average       : ${SKYBLUE}$load${PLAIN}"
echo -e " OS                 : ${SKYBLUE}$os_name${PLAIN}"
echo -e " Arch               : ${SKYBLUE}$arch (64 Bit)${PLAIN}"
echo -e " Kernel             : ${SKYBLUE}$kernel${PLAIN}"
echo -e " TCP CC             : ${SKYBLUE}$tcp_cc${PLAIN}"
echo -e " Virtualization     : ${SKYBLUE}$virt_type${PLAIN}"
echo -e " IPv4/IPv6          : $ipv4 / $ipv6"
echo -e " Organization       : ${SKYBLUE}$org${PLAIN}"
echo -e " Location           : ${SKYBLUE}$city / $country${PLAIN}"
echo -e " Region             : ${SKYBLUE}$region${PLAIN}"
next

# --- DISK I/O TEST ---
io1=$( (dd if=/dev/zero of=test_$$ bs=64k count=16k conv=fdatasync && rm -f test_$$) 2>&1 | awk -F, '{io=$NF} END { print io}' | sed 's/^[ \t]*//' )
io2=$( (dd if=/dev/zero of=test_$$ bs=64k count=16k conv=fdatasync && rm -f test_$$) 2>&1 | awk -F, '{io=$NF} END { print io}' | sed 's/^[ \t]*//' )
io3=$( (dd if=/dev/zero of=test_$$ bs=64k count=16k conv=fdatasync && rm -f test_$$) 2>&1 | awk -F, '{io=$NF} END { print io}' | sed 's/^[ \t]*//' )

v1=$(echo $io1 | awk '{print $1}')
v2=$(echo $io2 | awk '{print $1}')
v3=$(echo $io3 | awk '{print $1}')
unit=$(echo $io1 | awk '{print $2}')
avg=$(awk "BEGIN {printf \"%.1f\", ($v1 + $v2 + $v3) / 3}")

echo -e " I/O Speed(1st run) : ${YELLOW}$io1${PLAIN}"
echo -e " I/O Speed(2nd run) : ${YELLOW}$io2${PLAIN}"
echo -e " I/O Speed(3rd run) : ${YELLOW}$io3${PLAIN}"
echo -e " I/O Speed(average) : ${YELLOW}$avg $unit${PLAIN}"
next

# --- NETWORK SPEEDTEST ---
printf "%-18s %-15s %-15s %-15s\n" " Node Name" "Upload Speed" "Download Speed" "Latency"

speed_test() {
    local nodeName=$1
    local serverId=$2
    local args="--accept-license --accept-gdpr --format=json"
    
    if [[ -n "$serverId" ]]; then args="$args -s $serverId"; fi

    output=$(./speedtest $args 2>/dev/null)

    if [[ -n "$output" ]]; then
        ping=$(echo "$output" | grep -oP '"latency":\s*\K[0-9.]+' | head -1)
        dl=$(echo "$output" | grep -oP '"download":{"bandwidth":\s*\K[0-9]+' | head -1)
        ul=$(echo "$output" | grep -oP '"upload":{"bandwidth":\s*\K[0-9]+' | head -1)
        
        # Hitung Mbps
        dl_mbps=$(awk "BEGIN {printf \"%.2f
