#!/usr/bin/bash
# -x
#
# Bash script that uses curl to backup a ISAM appliance.
# #
# A script to create appliance snapshots.
# The script will create a snapshot, download it, and remove it
# from the appliance.
# #
#-------------------------------------------------------------------------
#Source the properties file for this script
PROPS_FILE=/apps/scripts/dev-snapshot.properties
if [ ! -f ${PROPS_FILE} ]; then
    echo "${PROPS_FILE} File not found!"
    exit 1
fi
. ${PROPS_FILE}

# The root directory for the backups.
TODAY=`date +%Y%m%d_%H%M%S`
BACKUPDIR=${BACKUP_ROOT}/${TODAY}

#-------------------------------------------------------------------------
function getSnapshots {
curl -H "Accept:application/json" --user "$1" "https://$2/snapshots" 2>>/dev/null
} #
#-------------------------------------------------------------------------
function getLastSnapshotID {
sl=`getSnapshots $1 $2`
echo $sl | sed 's/,/ \
/g' | grep "\"id\":" | tail -1 | sed 's/.*":"//' | sed 's/"//'
} #
#-------------------------------------------------------------------------
function getFirstSnapshotID {
sl=`getSnapshots $1 $2`
echo $sl | sed 's/,/ \
/g' | grep "\"id\":" | head -1 | sed 's/.*":"//' | sed 's/"//'
} #
#-------------------------------------------------------------------------
function createSnapshot {
data="{\"comment\":\"$3\"}"
curl -H "Accept:application/json" -d "$data" --insecure --max-time 900 --user "$1" "https://$2/snapshots"
2>>/dev/null
} #
#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
function createGetSnapshot {

r=`createSnapshot $1 $2 "$3"`
echo $r | sed 's/,/ \
/g' | grep "\"id\":" | sed 's/.*":"//' | sed 's/"//'
} #
#-------------------------------------------------------------------------
function downloadSnapshot {
curl -H "Accept:application/json" --insecure --user "$1" "https://$2/snapshots/download?record_ids=$3" > "$4" 2>>/dev/null
} #
#-------------------------------------------------------------------------
function deleteSnapshot {
curl -H "Accept:application/json" --insecure -X DELETE --user "$1" "https://$2/snapshots/$3"
2>>/dev/null
}
#=========================================================================
function takeSnapShot {
sid=`createGetSnapshot $1 "$2${DOMAIN}" "Created by backup script"`
if [ -z "$sid" ]; then
echo "ERROR Trying to backup $2"
echo "ERROR Trying to backup $2" | mail -s "Backup Error" ${NOTIFY}
else
`downloadSnapshot $1 "$2${DOMAIN}" $sid "${BACKUPDIR}/${2}.zip"`
`deleteSnapshot $1 "$2${DOMAIN}" $sid `
fi
}
#=========================================================================
# Main program.
#Add a takeSnapShot call for each appliance in the environment
# For clustered environments make calls to each appliance in the cluster as well
R=`mkdir -p ${BACKUPDIR}`
echo ${ADMUSER}
BAcreds="${ADMUSER}:${ADMPASS}"
echo "Taking snapshot of Policy server"
takeSnapShot ${BAcreds} ${POLICY_HOSTS} #Policy server
if [ "$POLICY_HOSTS" == "$WEBSEAL_HOSTS" ]; then
  echo "Policy and Webseal are on same host - running in DEV/FIT"
  echo " Skipping webseals ..."
else 
takeSnapShot ${BAcreds} ${WEBSEAL_HOSTS} #Webseal
fi
#takeSnapShot '${ADMUSER}:${ADMPASS}' ${WEBSEAL_HOST} #Policy server

echo " Snapshot file(s) are stored in $BACKUPDIR"
echo "Exiting ..."
exit 0
