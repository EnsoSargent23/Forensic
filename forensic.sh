#!/bin/bash

# Forensik Sammelskript – Schneller Snapshot
TIMESTAMP=$(date '+%F_%H%M%S')
OUTFILE="forensik_$HOSTNAME_$TIMESTAMP.txt"
ISROOT=false
[ "$EUID" -eq 0 ] && ISROOT=true

section() {
    echo -e "\n======================================"
    echo "[SEKTION] $1 - $(date)"
    echo "======================================"
}

subsection() {
    echo -e "\n---------- $1 ----------"
}

exec > "$OUTFILE" 2>&1

section "SYSTEMINFOS"
uname -a
uptime
hostname
date
whoami
id

section "BENUTZER & LOGIN"
who
last -n 10
lastlog | grep -v '**Never'

section "NETZWERK"
ip a
subsection "Offene Verbindungen"
ss -tunap 2>/dev/null || netstat -tunap 2>/dev/null

section "PROZESSE"
ps aux --sort=-%mem | head -n 15

section "AUTOSTART / CRONTABS"
subsection "Benutzer-Crontab"
crontab -l 2>/dev/null
subsection "System-Crontabs"
[ "$ISROOT" = true ] && ls -la /etc/cron* /var/spool/cron/ 2>/dev/null

section "DATEIÄNDERUNGEN (HOME)"
find $HOME -type f -printf '%TY-%Tm-%Td %TH:%TM:%TS %p\n' 2>/dev/null | sort -r | head -n 25

section "BASH-HISTORY"
tail -n 30 ~/.bash_history 2>/dev/null

section "WICHTIGE LOGS"
if [ "$ISROOT" = true ]; then
    subsection "auth.log"
    tail -n 50 /var/log/auth.log 2>/dev/null
    subsection "syslog"
    tail -n 50 /var/log/syslog 2>/dev/null
else
    echo "[!] Keine Rootrechte – eingeschränkter Zugriff auf Logs"
fi

section "HASHES wichtiger Dateien im Home (Shellskripte)"
find "$HOME" -type f -name "*.sh" -exec sha256sum {} \; 2>/dev/null

section "FERTIG"
echo "Forensikbericht gespeichert unter: $OUTFILE"
