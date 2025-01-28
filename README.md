System Audit Script
A comprehensive system audit program that performs 40 checks on a Linux machine, outputting results in a single CSV file with special character handling. It includes checks for disk usage, memory usage, kernel version, services, SSSD status, Tomcat status, and more.

Features
40 Automated Checks:

OS & Kernel: Displays OS version, kernel version, and ensures kernel consistency.
Hardware/Resources: Checks CPU usage, memory usage, partitions, disk usage (in GB), large files, swap usage/configuration, and system uptime/load.
Services & Processes: Reports on running processes, zombie processes, open ports, disk I/O, network stats, top CPU/memory-consuming processes, file descriptors, and active services.
Startup & Logging: Shows which services start on boot, failed systemd units, and log aggregation tools.
Authentication: Checks SSSD status, tests user ctrek for domain authentication, lists local accounts, verifies wheel group config, and shows sudo users.
Tomcat & Monitoring: Checks Tomcat status/version, plus installed monitoring tools (Zabbix, Ninja, CrowdStrike, ArmorPoint).
Package/YUM Checks: Displays installed packages, YUM repositories, available updates.
HAProxy: Checks if HAProxy is installed or running.
Last User Login: Shows recent login history for the machine.
CSV Output: Escapes quotes and newlines to maintain integrity in spreadsheet applications.
Special Character Handling: Ensures any quotes (") or newlines in command outputs are escaped so they won't break the CSV format.

Progress Logging: Displays a message for each check in the terminal, e.g. "Running check 1/40: OS Version", so you can see what the script is currently doing.

Usage
Clone or Copy this repository to your local machine.

Make the Script Executable:

bash
Copy
Edit
chmod +x system_audit.sh
Run the Script:

bash
Copy
Edit
./system_audit.sh
Output:

As the script runs, it will print messages like Running check N/40: <description>.
When finished, it creates system_audit_report.csv in the same directory with one line per check. Each line has three columns:
arduino
Copy
Edit
"Category","Description","Details"
Checks Overview
Below is a categorized summary of the 40 checks:

System / OS Info

Check OS version (/etc/os-release)
Check kernel version (uname -r)
Check kernel consistency (rpm -q kernel)
Hardware / Resource Info

CPU usage (top -bn1)
Memory usage (free -h)
Partitions (lsblk)
Disk usage in GB (df -BG)
Large files (exclude NFS, find / -size +100M -xdev)
Swap usage/configuration (swapon --show, /proc/swaps)
System uptime (uptime -p)
System load averages (uptime)
Services / Processes / Networking

Running processes (top 20 sorted by CPU/mem)
Zombie processes
Open ports (ss -tuln)
Disk I/O stats (iostat)
Network stats (ifconfig)
Top CPU-consuming processes
Top memory-consuming processes
File descriptors in use (lsof | wc -l)
Startup & Logging

Active systemd services
Services started on boot
Broken/failed systemd units
Log aggregation tools (checks for fluentd|logstash|filebeat|rsyslog)
Authentication

SSSD status and enabled state
Test SSSD with user some_user (modify as needed)
Local accounts (UID >= 1000)
Wheel group configuration
Sudo users
Tomcat & Monitoring

Tomcat status/version (reads catalina.jar)
Monitoring tools (Zabbix, Ninja, CrowdStrike, ArmorPoint)
Package / YUM Checks

Installed packages (sample of first 20)
YUM repos (yum repolist)
System updates (yum check-update)
Additional Tools

HAProxy installed/running
Separate refined check for CrowdStrike/Ninja if needed
Security / Login History

Last user login (last -n 10)
Misc.

uLimit info (ulimit -a)
Customization
SSSD Test User: By default, the script tests id some_user to confirm SSSD domain membership. You can change some_user to a valid domain user in your environment.
Head / Sample Lines: Many commands use head -n 20 or head -n 10 to limit output size. You can adjust these as desired.
File Size / NFS: Uses -xdev to avoid crossing NFS mounts when searching large files. Adjust if you wish to include or exclude network storage.
Requirements
Bash (tested on CentOS/RHEL-like systems, but should work on most modern Linux distros).
Packages: Some checks use tools like iostat (in sysstat), lsof, yum, rpm, top, ss, etc. Make sure they’re installed if you need those checks to succeed.
