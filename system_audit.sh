#!/bin/bash
#=============================================================
# Comprehensive System Audit Script - 40 Checks
# questions, email me:  jmaster777@hotmail.com
# send me some BTC:  32Snf9gNNVhPs8yZq6KpdSXYjDYZb8UoQL
# Outputs results to a single CSV file named system_audit_report.csv
#
# Displays "Running check #n: <description>" before each check
# CSV output with special character handling
#=============================================================

CSV_FILE="system_audit_report.csv"

#-------------------------------------------------------------
# CSV Escaping
#  - Replaces '"' with '""'
#  - Replaces newline with '\n'
#-------------------------------------------------------------
escape_csv() {
    local data="$1"
    data="${data//\"/\"\"}"       # Escape quotes
    data="${data//$'\n'/\\n}"     # Escape newlines
    echo "$data"
}

#-------------------------------------------------------------
# Output a row to CSV
#  - Enclose fields in quotes
#  - Use escape_csv() to handle special chars
#-------------------------------------------------------------
output_csv_row() {
    local category="$1"
    local description="$2"
    local data="$3"

    local cat_escaped
    local desc_escaped
    local data_escaped

    cat_escaped=$(escape_csv "$category")
    desc_escaped=$(escape_csv "$description")
    data_escaped=$(escape_csv "$data")

    echo "\"$cat_escaped\",\"$desc_escaped\",\"$data_escaped\"" >> "$CSV_FILE"
}

# Start fresh CSV with headers
echo "\"Category\",\"Description\",\"Details\"" > "$CSV_FILE"

# Helper function to show the check number and description
run_check() {
    local number="$1"
    local description="$2"
    echo "Running check $number: $description"
}

#=============================================================
# 1) System / OS Info
#=============================================================
run_check "1/40" "OS Version"
os_release="$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d= -f2- | tr -d '"')"
output_csv_row "OS Version" "Details" "${os_release:-Unknown}"

run_check "2/40" "Kernel Version"
kernel_version="$(uname -r)"
output_csv_row "Kernel Version" "Details" "$kernel_version"

run_check "3/40" "Kernel Consistency"
output_csv_row "Kernel Consistency" "Details" "$(rpm -q kernel 2>/dev/null)"

#=============================================================
# 2) Hardware / Resource Info
#=============================================================
run_check "4/40" "CPU Usage"
cpu_usage="$(top -bn1 | grep "Cpu(s)" | sed 's/\s\+/ /g')"
output_csv_row "CPU Usage" "Details" "${cpu_usage:-No CPU info found}"

run_check "5/40" "Memory Usage"
memory_usage="$(free -h | sed 's/\s\+/ /g')"
output_csv_row "Memory Usage" "Details" "$memory_usage"

run_check "6/40" "Partitions"
partitions="$(lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT | grep -v loop | sed 's/\s\+/ /g')"
output_csv_row "Partitions" "List" "$partitions"

run_check "7/40" "Disk Usage in GB"
disk_usage="$(df -BG | sed 's/\s\+/ /g')"
output_csv_row "Disk Usage (GB)" "Details" "$disk_usage"

run_check "8/40" "Large Files (skips nfs)"
large_files="$(find / -type f -size +100M -not -fstype nfs 2>/dev/null | head -n 50)"
output_csv_row "Large Files" "Details" "${large_files:-No large files found}"

run_check "9/40" "Swap Usage"
swap_details="$(swapon --show 2>/dev/null)"
output_csv_row "Swap Usage" "Details" "${swap_details:-No swap configured}"

run_check "10/40" "Swap Partition Configuration"
swap_partition="$(cat /proc/swaps 2>/dev/null)"
output_csv_row "Swap Partition" "Details" "${swap_partition:-No swap partition found}"

run_check "11/40" "System Uptime"
uptime_data="$(uptime -p)"
output_csv_row "System Uptime" "Details" "$uptime_data"

run_check "12/40" "System Load"
system_load="$(uptime | awk -F "load average:" '{print $2}' | sed 's/^\s*//;s/\s*$//')"
output_csv_row "System Load" "Details" "${system_load:-No load info found}"

#=============================================================
# 3) Services / Processes / Networking
#=============================================================
run_check "13/40" "Running Processes (top 20)"
running_procs="$(ps aux --sort=-%cpu,-%mem | head -n 20 | sed 's/\s\+/ /g')"
output_csv_row "Running Processes" "Details" "${running_procs:-None found}"

run_check "14/40" "Zombie Processes"
zombie_procs="$(ps aux | awk '$8 == "Z"')"
output_csv_row "Zombie Processes" "Details" "${zombie_procs:-No zombie processes found}"

run_check "15/40" "Open Ports"
if command -v ss &>/dev/null; then
    ports="$(ss -tuln)"
else
    ports="$(netstat -tuln 2>/dev/null)"
fi
output_csv_row "Open Ports" "Details" "${ports:-No open ports found}"

run_check "16/40" "Disk I/O"
disk_io="$(iostat -dx 2>/dev/null | head -n 20)"
output_csv_row "Disk I/O" "Details" "${disk_io:-No iostat info found}"

run_check "17/40" "Network Stats"
if command -v ifconfig &>/dev/null; then
    net_stats="$(ifconfig 2>/dev/null | sed 's/\s\+/ /g')"
elif command -v ip &>/dev/null; then
    net_stats="$(ip -o addr show 2>/dev/null | sed 's/\s\+/ /g')"
else
    net_stats=""
fi
output_csv_row "Network Stats" "Details" "${net_stats:-No network interface found}"

run_check "18/40" "Top 10 CPU-consuming Processes"
top_cpu="$(ps aux --sort=-%cpu | head -n 10 | sed 's/\s\+/ /g')"
output_csv_row "Top CPU Processes" "Details" "${top_cpu:-No processes found}"

run_check "19/40" "Top 10 Memory-consuming Processes"
top_mem="$(ps aux --sort=-%mem | head -n 10 | sed 's/\s\+/ /g')"
output_csv_row "Top Memory Processes" "Details" "${top_mem:-No processes found}"

run_check "20/40" "File Descriptors"
fd_count="$(lsof 2>/dev/null | wc -l)"
output_csv_row "File Descriptors" "Count" "$fd_count"

#=============================================================
# 4) Services, Startup, Logs
#=============================================================
run_check "21/40" "Service Configurations (active)"
services_list="$(systemctl list-units --type=service --state=active | head -n 20 | sed 's/\s\+/ /g')"
output_csv_row "Service Configurations" "Details" "$services_list"

run_check "22/40" "Services Started on Boot"
boot_services="$(systemctl list-unit-files --type=service | grep enabled | head -n 20 | sed 's/\s\+/ /g')"
output_csv_row "Boot Services" "Details" "${boot_services:-None found}"

run_check "23/40" "Broken Startup Scripts (systemd failed)"
failed_startup="$(systemctl --failed | head -n 10 | sed 's/\s\+/ /g')"
output_csv_row "Failed Startup Scripts" "Details" "${failed_startup:-None found}"

run_check "24/40" "Log Aggregation Tools"
log_agg_tools="$(rpm -qa | grep -E 'fluentd|logstash|filebeat|rsyslog')"
output_csv_row "Log Aggregation" "Details" "${log_agg_tools:-None found}"

#=============================================================
# 5) Authentication and Accounts
#=============================================================
run_check "25/40" "SSSD Status"
if systemctl is-active --quiet sssd; then
    sssd_status="Active"
else
    sssd_status="Inactive"
fi
output_csv_row "SSSD" "Status" "$sssd_status"

if systemctl is-enabled --quiet sssd; then
    sssd_enabled="Enabled"
else
    sssd_enabled="Disabled"
fi
output_csv_row "SSSD" "Enabled" "$sssd_enabled"

sssd_domains="$(grep "domains" /etc/sssd/sssd.conf 2>/dev/null | awk -F= '{print $2}' | tr -d ' ')"
output_csv_row "SSSD" "Configured Domains" "${sssd_domains:-No domains configured}"

run_check "26/40" "Test SSSD with account some_user"
if id "some_user" &>/dev/null; then
    output_csv_row "SSSD Test" "Account Check" "Success: some_user found"
else
    output_csv_row "SSSD Test" "Account Check" "Failed: some_user not found"
fi

run_check "27/40" "Local Accounts (UID >= 1000)"
local_accounts="$(awk -F: '$3 >= 1000 && $3 < 65534 {print $1 ":" $3 ":" $6}' /etc/passwd)"
output_csv_row "Local Accounts" "user:uid:home" "${local_accounts:-No local accounts found}"

run_check "28/40" "Wheel Group Config"
wheel_conf="$(grep '^%wheel' /etc/sudoers 2>/dev/null; grep '^%wheel' /etc/sudoers.d/* 2>/dev/null)"
output_csv_row "Wheel Group" "Configuration" "${wheel_conf:-No wheel group config found}"

run_check "29/40" "Sudo Users"
sudo_users="$(getent group sudo | awk -F: '{print $4}' | tr -d ' ')"
output_csv_row "Sudo Users" "Users with Sudo Access" "${sudo_users:-None found}"

#=============================================================
# 6) Tomcat & Monitoring
#=============================================================
run_check "30/40" "Tomcat Check"
# Already done above, but we place a simple echo to clarify the logs
# The actual Tomcat lines are executed at runtime. 
# If you want to see them inline, you can move them here.

ps aux | grep org.apache.catalina.startup.Bootstrap | grep -v grep | while read -r line; do
    catalina_home=$(echo "$line" | grep -oP '(?<=-Dcatalina.home=)[^ ]+')
    if [[ -n $catalina_home ]]; then
        version_file="$catalina_home/lib/catalina.jar"
        if [[ -f $version_file ]]; then
            tomcat_version=$(unzip -p "$version_file" org/apache/catalina/util/ServerInfo.properties 2>/dev/null \
                             | grep "server.info" | awk -F= '{print $2}')
            output_csv_row "Tomcat" "Tomcat Status" "Running"
            output_csv_row "Tomcat" "Tomcat Version" "${tomcat_version:-Version information not found}"
        else
            output_csv_row "Tomcat" "Tomcat Status" "Running"
            output_csv_row "Tomcat" "Tomcat Version" "Version information not found"
        fi
    else
        output_csv_row "Tomcat" "Tomcat Status" "Not Running"
        output_csv_row "Tomcat" "Tomcat Version" "CATALINA_HOME not found"
    fi
done

run_check "31/40" "Monitoring Tools"
monitoring_tools="$(rpm -qa | grep -E 'zabbix|ninja|crowdstrike|armorpoint')"
output_csv_row "Monitoring Tools" "Installed Tools" "${monitoring_tools:-None found}"

#=============================================================
# 7) Package / YUM Checks
#=============================================================
run_check "32/40" "Installed Packages (first 20)"
installed_pkgs="$(rpm -qa | head -n 20)"
output_csv_row "Installed Packages" "Details" "${installed_pkgs:-No packages found}"

run_check "33/40" "YUM Repos"
yum_repos="$(yum repolist 2>/dev/null)"
output_csv_row "YUM Repos" "Repolist" "${yum_repos:-Could not retrieve repo list}"

run_check "34/40" "System Updates (yum check-update)"
updates="$(yum check-update 2>/dev/null)"
if [[ -z "$updates" ]]; then
    output_csv_row "System Updates" "Status" "No updates available or no repo data found"
else
    output_csv_row "System Updates" "Available Updates" "$updates"
fi

#=============================================================
# 8) Additional Tools (HAProxy, etc.)
#=============================================================
run_check "35/40" "HAProxy Configuration"
haproxy_installed="$(rpm -qa | grep -i haproxy)"
if [[ -n "$haproxy_installed" ]]; then
    haproxy_service="$(systemctl is-active haproxy 2>/dev/null)"
    haproxy_status="Installed"
    if [[ "$haproxy_service" == "active" ]]; then
        haproxy_status+=" and running"
    else
        haproxy_status+=" (not running)"
    fi
    output_csv_row "HAProxy" "Configuration" "$haproxy_status"
else
    output_csv_row "HAProxy" "Configuration" "Not installed"
fi

run_check "36/40" "Refined: CrowdStrike / Ninja Tools"
cn_tools="$(rpm -qa | grep -Ei 'crowdstrike|ninja' 2>/dev/null)"
output_csv_row "CrowdStrike/Ninja" "Installed Tools" "${cn_tools:-None found}"

#=============================================================
# 9) Security / Login History
#=============================================================
run_check "37/40" "Last User Login"
last_logins="$(last -n 10 2>/dev/null)"
output_csv_row "Last User Login" "Recent Logins" "${last_logins:-No login history found}"

#=============================================================
# 10) Additional Checks
#=============================================================
run_check "38/40" "uLimit"
ulimits="$(ulimit -a | sed 's/\s\+/ /g')"
output_csv_row "uLimit" "Details" "$ulimits"

run_check "39/40" "Broken Startup Scripts (duplicate or additional info)"
# We already did a "Failed Startup Scripts" check at #23, 
# so you may not need this unless you want a second pass.
# We'll keep a placeholder for demonstration:
fail_start2="$(systemctl --failed | sed 's/\s\+/ /g')"
output_csv_row "Failed Scripts (Addl)" "Details" "${fail_start2:-None found}"

run_check "40/40" "Done"
echo "System audit completed with 40 checks. Results are in '$CSV_FILE'."
