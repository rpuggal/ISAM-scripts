#!/bin/sh
 #########################Script to download WebSEAL request.log file Daily#####################################

echo "Script to download WebSEAL request.log file Everyday---------------------------------------"
echo
echo Ignore "command not found" errors related to WebSEAL instances.

log()
{
  if [ "$LOG_FILE" != "" ]
  then
    echo `date +%Y-%m-%d-%H:%M:%S` $@ >> $LOG_FILE
  fi
}

check_dir_exists()
{
  if [ ! -d "$1" ]
  then
    log "Directory $1 does not exist."
    echo "ERROR: Directory $1 does not exist."
    exit 1
  fi
}


#
# check_file_exists
#   Utility function to verify if a file exists and
#   terminate with a fatal error if not.
#
#
check_file_exists()
{
  if [ ! -f "$1" ]
  then
    log "File $1 does not exist."
    echo "ERROR: File $1 does not exist."
    exit 1
  fi
}


Property_file_path=/apps/scripts/dev-WebSEALInstances.properties
if [ ! -f ${Property_file_path} ]; then
    echo "${Property_file_path} File not found!"
    exit 1
fi

Today=$(date +'%d/%b/%Y')

dat1=$(date)

. $Property_file_path

cd $Destination

# Start logging
TIMESTAMP=`date +%Y-%m-%d-%H-%M-%S`
LOG_FILE=$Destination/log/Download-$TIMESTAMP.log
> $LOG_FILE

log "Log Managegement tool started."


awk '/Instances:server1/{flag=1;next}/ENDInstances1/{flag=0}flag' $Property_file_path > Instances1
awk '/Instances:server2/{flag=1;next}/ENDInstances2/{flag=0}flag' $Property_file_path > Instances2

cat Instances1 | while read line
do
#Exporting an instance-specific log file
STATUS=$(curl -k -s -o /dev/null -w '%{http_code}'  --user $UserName:$Password -H Content-type:application/json -H Accept:application/json -s -X GET -d @$data $Server1/$line/request.log?export -o ${line}_request.log)
echo $STATUS
if [ $STATUS -eq 200 ]; then
    echo "Downloaded request log to ${line}_request.log ..."
    log "Downloaded request log to ${line}_request.log ..."
    curl -k -s -o /dev/null -w '%{http_code}'--user $UserName:$Password -H Content-type:application/json -H Accept:application/json -s -X DELETE  -d @$data $Server1/$line/request.log}
	echo $STATUS
else
    echo "Got $STATUS :( Not done yet..."
    log "Got $STATUS :( Not done yet..."

fi


cat Instances2 | while read line
do
#Exporting an instance-specific log file
STATUS=$(curl -k -s -o /dev/null -w '%{http_code}'  --user $UserName:$Password -H Content-type:application/json -H Accept:application/json -s -X GET -d @$data $Server2/$line/request.log?export -o ${line}_request.log)
echo $STATUS
if [ $STATUS -eq 200 ]; then
    echo "Downloaded request log to ${line}_request.log ..."
    log "Downloaded request log to ${line}_request.log ..."
    curl -k -s -o /dev/null -w '%{http_code}'--user $UserName:$Password -H Content-type:application/json -H Accept:application/json -s -X DELETE  -d @$data $Server2/$line/request.log}
	echo $STATUS
else
    echo "Got $STATUS :( Not done yet..."
    log "Got $STATUS :( Not done yet..."

fi



#curl -k --user $UserName:$Password -H Content-type:application/json -H Accept:application/json -s -X GET -d @$data $Server1/$line/request.log?export -o ${line}_request.log
#Clearing an instance-specific log file
#curl -k --user $UserName:$Password -H Content-type:application/json -H Accept:application/json -s -X DELETE  -d @$data $Server1/$line/request.log
done


#cat *_request.log >> consolidate.log
#cat  *_request.log | gzip > "Archive_`date +'%Y%m%d'`".zip 
check_file_exists *_request.log
tar -czvf  "Archive_`date +'%Y%m%d'`".gz *_request.log
mv Archive_*.gz $Destinationpath
#Cleanup temp files
cd $Destination
check_file_exists Instances1 
check_file_exists Instances2 
rm -f Instances1 Instances2 
#rm -f *_request.log

echo " Final Logfile zipped and copied to $Destinationpath ..."
echo -------------------------------------------Execution Finished -----------------------------------------------
log " Final Logfile zipped and copied to $Destinationpath ..."
log " -------------------------------------------Execution Finished -----------------------------------------------"
exit 0
