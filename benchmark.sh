#!/bin/bash

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
SKYBLUE='\033[0;36m'
BLUE='\033[0;34m'
PLAIN='\033[0m'

# --- 1. PREPARATION: Download Speedtest-Go (Anti-Dependency) ---
# Kita pakai engine Go-Lang yang tidak butuh library system
rm -f speedtest-go speedtest.tar.gz

# Download Binary
wget -q -O speedtest.tar.gz https://github.com/showwin/speedtest-go/releases/download/v1.7.9/speedtest-go_1.7.9_linux_x86_64.tar.gz

# Extract
if [ -f speedtest.tar.gz ]; then
    tar -zxf speedtest.tar.gz speedtest-go
    chmod +x speedtest-go
    rm speedtest.tar.gz
else
    echo "Error: Gagal download engine."
fi

clear

# Fungsi Garis Separator
next() {
    printf "%-70s\n" "-" | sed 's/ /-/g'
}

# --- HEADER (LOGO KULI) ---
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
echo -e " Version            : ${GREEN}v2025-11-24 (V14 Go-Engine)${PLAIN}"
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
swap_used=$(free -h | awk '/^Swap:/ {print $2}')

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

# --- NETWORK SPEEDTEST (GO ENGINE) ---
printf "%-18s %-15s %-15s %-15s\n" " Node Name" "Upload Speed" "Download Speed" "Latency"

speed_test() {
    local nodeName=$1
    local serverId=$2
    local args="--json"
    
    if [[ -n "$serverId" ]]; then args="$args --server=$serverId"; fi

    # Cek binary
    if [ ! -f "./speedtest-go" ]; then
         printf " ${YELLOW}%-18s${PLAIN} ${RED}%-15s${PLAIN} ${RED}%-15s${PLAIN} ${RED}%-15s${PLAIN}\n" "$nodeName" "No Binary" "Error" "Error"
         return
    fi

    # Execute Speedtest-Go
    output=$(./speedtest-go $args 2>/dev/null)

    if [[ -n "$output" ]]; then
        # Parsing JSON from Go-Speedtest (Struktur beda dikit dari Python)
        # Output Speedtest-Go: {"Ping":..., "Download":..., "Upload":...}
        # Nilai Download/Upload dalam bit per second (bps)
        
        ping=$(echo "$output" | grep -oP '"Latency":\s*\K[0-9.]+' | head -1)
        # Jika Latency kosong, coba field "Ping"
        if [[ -z "$ping" ]]; then ping=$(echo "$output" | grep -oP '"Ping":\s*\K[0-9.]+' | head -1); fi
        
        dl_raw=$(echo "$output" | grep -oP '"Download":\s*\K[0-9.]+' | head -1)
        ul_raw=$(echo "$output" | grep -oP '"Upload":\s*\K[0-9.]+' | head -1)
        
        if [[ -z "$ping" ]] || [[ -z "$dl_raw" ]]; then
             printf " ${YELLOW}%-18s${PLAIN} ${RED}%-15s${PLAIN} ${RED}%-15s${PLAIN} ${RED}%-15s${PLAIN}\n" "$nodeName" "Error" "Fail" "Timeout"
             return
        fi

        # Convert bps to Mbps (Val / 1000000)
        dl_mbps=$(awk "BEGIN {printf \"%.2f\", $dl_raw / 1000000}")
        ul_mbps=$(awk "BEGIN {printf \"%.2f\", $ul_raw / 1000000}")
        
        # Parse Ping to ms (Kadang outputnya nanoseconds, kita cek range)
        # Speedtest-go biasanya ms atau duration string. Kita ambil angka saja.
        # Asumsi output float ms.
        
        printf " ${YELLOW}%-18s${PLAIN} ${GREEN}%-15s${PLAIN} ${RED}%-15s${PLAIN} ${SKYBLUE}%-15s${PLAIN}\n" "$nodeName" "${ul_mbps} Mbps" "${dl_mbps} Mbps" "${ping} ms"
    else
        printf " ${YELLOW}%-18s${PLAIN} ${RED}%-15s${PLAIN} ${RED}%-15s${PLAIN} ${RED}%-15s${PLAIN}\n" "$nodeName" "Fail" "Fail" "Timeout"
    fi
}

# --- LIST SERVER TEST ---
# Test Otomatis (Cari terdekat)
speed_test "Closest/Auto" ""

# Test Manual (ID Server Speedtest.net)
speed_test "Jakarta" "11116"
speed_test "Singapore" "13623"
speed_test "Tokyo, JP" "15047"
speed_test "Los Angeles" "17381"

# Cleanup
rm speedtest-go 2>/dev/null

next
duration=$SECONDS
echo -e " Finished in        : $(($duration / 60)) min $(($duration % 60)) sec"
echo -e " Timestamp          : $(date '+%Y-%m-%d %H:%M:%S %Z')"
next
