#!/bin/bash
# HTB Enumeration Script
# LoRKa

command -v nmap >/dev/null 2>&1 || { echo -e >&2 "[\e[1;31m!\e[0m] You need \e[1;32mnmap\e[0m , please install it."; exit 1; }
command -v whatweb >/dev/null 2>&1 || { echo -e >&2 "[\e[1;31m!\e[0m] You need \e[1;32mwhatweb\e[0m , please install it."; exit 1; }
command -v curl >/dev/null 2>&1 || { echo -e >&2 "[\e[1;31m!\e[0m] You need \e[1;32mcurl\e[0m , please install it."; exit 1; }

if [ "$#" -ne "2" ] || [ "$#" -gt "2" ] ; then
echo "[+] Use: $(basename $0) machineNAME machineIP"
echo "[+] Exp: $(basename $0) Armageddon 10.10.10.233"
exit -1
fi

trap '/bin/rm -rf "$TMPFILE"' EXIT

#Vars
NAME="$1"
IP="$2"
TMPFILE=$(mktemp)
FOLDER="/hackthebox/$NAME"


#Functions
checkvpn(){
ip -4 a show tun0 1>/dev/null 2>/dev/null
if [ $? -ne 0 ];then
printf '%s\n' "[!] ERROR: la VPN no esta conectada :("
exit -1
fi
}

checkping(){
timeout 0.3 ping -c1 $IP 1>/dev/null 2>/dev/null
if [ $? -ne 0 ];then
printf '%s\n' "[!] ERROR: la ip $IP no contesta a ping :("
exit -1
fi
}

createfolder(){
if [ -d "$FOLDER" ]; then
printf '%s\n' "[!] Cuidado! el directorio $FOLDER existe!"
exit -1
fi
mkdir -p $FOLDER
}


addhost(){
local HOSTSFILE="/etc/hosts"
local HOSTNAME="$NAME.htb"
local IP="$IP"
local LINE="$IP\t$HOSTNAME"
if [ -n "$(grep $HOSTNAME $HOSTSFILE)" ]
then
printf '%s\n' "[!] $HOSTNAME ya existe en $HOSTSFILE : $(grep $HOSTNAME $HOSTSFILE)"
else
sh -c -e "echo '$LINE' >> $HOSTSFILE";
        if [ -n "$(grep $HOSTNAME $HOSTSFILE)" ]
        then
        :
        else
        printf '%s\n' "[+] Error al agregar $HOSTNAME, prueba de nuevo!";
        fi
fi
}

scan(){
/usr/bin/nmap -p- -sS --min-rate 5000 --open -vvv -n -Pn -oG $TMPFILE $IP
local PORTS=$(/bin/cat $TMPFILE |grep -oP '\d{1,5}/open' |awk '{print $1}' FS='/' | xargs | tr ' ' ',')
/usr/bin/nmap -sC -sV -p$PORTS -oN $FOLDER/nmap.txt $IP
}

webinfo(){
local OUTPUT="$FOLDER/webinfo.txt"
if cat $TMPFILE |grep -oP '\d{1,5}/open' |awk '{print $1}' FS='/' |grep -w '80'; then
    whatweb http://$NAME.htb >> $OUTPUT
    echo "" >> $OUTPUT
    curl -s -I -X GET http://$NAME.htb >> $OUTPUT
elif cat $TMPFILE |grep -oP '\d{1,5}/open' |awk '{print $1}' FS='/' |grep -w '443'; then
    whatweb https://$NAME.htb >> $OUTPUT
    echo "" >> $OUTPUT
    curl -s -k -I -X GET https://$NAME.htb >> $OUTPUT
fi
}

#RunAway
checkvpn
checkping
createfolder
addhost
scan
webinfo

