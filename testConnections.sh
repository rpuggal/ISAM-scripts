#!/bin/bash
#set -x

ADMUSER="admin"
PWD="xxxxxx"
TIMEOUT=2

function runConnect {
    HDR="Accept:application/json"
    API="core/net/connect"
    appliance_hostname=$1
    OPTIONS='{"ssl":false,"server":"'$2'","port":'$3',"timeout":'$TIMEOUT'}'
    echo "Checking $appliance_hostname..."
    curl -k -s -H 'Accept:application/json' -u $ADMUSER:$PWD https://$appliance_hostname/$API -d "$OPTIONS"
    echo;
}



function readFile {
     infile=$1
    if [[ ! -f "$infile" ]]; then echo "$infile isnt a file."; exit 1; fi
    echo "Reading file $infile"
    while i= read -r entry
    do
        if [ ! -z "$entry" ]; then
            local IFS=","
            connvars=($entry)
            #echo "${connvars[0]} ${connvars[1]} ${connvars[2]}"
            runConnect ${connvars[0]} ${connvars[1]} ${connvars[2]}
        fi
    done <"$infile"
}


case $# in
0) echo "Provide either an input file or hostname ip port" ; exit 1;;
1) readFile $1   ;; ## connect_out$(date +%m%d%Y).txt
2) echo "Provide either an input file or hostname ip port"; exit 1;;
3) echo "Testing ip $2  port $3 on appliance $1"; runConnect $1 $2 $3;;
esac


