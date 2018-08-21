#!/bin/bash
set -x
# NEED TO UNSET THE WEBHOST PARAMETER.
# HTTP TAG VALUES NEED TO BE MIGRATED AS WELL.

###############################
# Initialize variables.

function initializevariables
{
echo
echo INITIALIZING VARIABLES...
echo
echo
RPINSTANCE=spb-dev2
#NEWRPINSTANCE=
SHAREDOBJECTSPACE=spb-dev2
#NEWRPINSTANCE=$RPINSTANCE
RPIP=0.0.0.0
#RPIP=10.20.134.39
OLDRPLMIHOST=cilwbsld0001.sys.cigna.com
USERNAME=admin
PASS=admin2
RPLMIHOST=cilwbsld0001.sys.cigna.com
HOMEDIR=/home/ivmgr/taylorr
HTTPSPORT=8475
INSTANCEHOME=$HOMEDIR/$RPINSTANCE
ISAMZIP=spb-dev2_isam9export.zip
ZIPFILENAME=$RPINSTANCE.zip

}

##############################
# Create RP instance.


function createrpinstance
{
echo
echo CREATING RP INSTANCE
echo
echo
# This command is unable to accept variables in the -d parameter for some reason.
# Therefore everything in the -d parameter must be hardcoded for now, until we figure it out.
curl -H 'Accept:application/json' -k -u $USERNAME:$PASS -X POST https://$RPLMIHOST/wga/reverseproxy -d '{"inst_name":"stage-yourcareallies","host":"ciaisapd0055.sys.cigna.com","listening_port
":"7236","domain":"default9","admin_id":"sec_master","admin_pwd":"Tam123","ssl_yn":"yes","key_file":"ldap_ssl.kdb","ssl_port":"636","http_yn":"no","http_port":"80","https_yn":"yes","https_por
t":"8445","nw_interface_yn":"yes","ip_address":"10.20.134.39"}'
echo
echo
echo DONE CREATING RP INSTANCE
}
################################
# Export TAM6 configuration.

function exporttam6 ()
{
echo
echo EXPORTING TAM6CONFIGURATION..
echo
echo
rm -rf $INSTANCEHOME
perl $HOMEDIR/wga_migrate.pl -c /opt/pdweb/etc/webseald-$RPINSTANCE.conf -v -d $INSTANCEHOME
perl -pi -e 's/^network-interface =/\#network-interface/' $INSTANCEHOME/etc/webseald-$RPINSTANCE.conf
perl -pi -e 's/^ssl-enabled = yes/\ssl-enabled = no/' $INSTANCEHOME/etc/webseald-$RPINSTANCE.conf
perl -pi -e 's/^ssl-keyfile = /\#ssl-keyfile = /' $INSTANCEHOME/etc/webseald-$RPINSTANCE.conf
perl -pi -e 's/^http = yes/http = no/' $INSTANCEHOME/etc/webseald-$RPINSTANCE.conf
cd $INSTANCEHOME
rm $ZIPFILENAME
zip -r $INSTANCEHOME/$RPINSTANCE.zip *
#mv $INSTANCEHOME/$RPINSTANCE.zip ..
}
###############################
# Export from ISAM9

function exportisam9 ()
{
echo
echo EXPORTING ISAM9 CONFIGURATION...
echo
echo
curl -H 'Accept:application/json' -k -u $USERNAME:$PASS -X GET https://$OLDRPLMIHOST/wga/reverseproxy/$RPINSTANCE?action=export -o $ISAMZIP
}
###############################

function importtam6config ()
{
echo
echo "IMPORTING CONFIGURATION FILE FROM TAM6 ZIP FILE $ZIPFILENAME INTO RP INSTANCE $NEWRPINSTANCE ON $RPLMIHOST."
echo
echo
curl -k -H 'Accept:application/json' -u $USERNAME:$PASS -X POST https://$RPLMIHOST/wga/reverseproxy/$NEWRPINSTANCE/migrate --form file=@$ZIPFILENAME --form overwrite=true
echo
echo
echo
}
###############################
function importisam9config ()
{
echo
echo "IMPORTING CONFIGURATION FILE FROM ISAM9 ZIP FILE INTO RP INSTANCE $NEWRPINSTANCE ON $RPLMIHOST."
echo
echo
curl -k -H 'Accept:application/json' -u $USERNAME:$PASS -X POST https://$RPLMIHOST/wga/reverseproxy/$NEWRPINSTANCE/migrate --form file="@$ISAMZIP" --form overwrite=true
echo
echo
echo
}

###############################

function networkinterface ()
{
echo
echo "UPDATING NETWORK INTERFACE SETTINGS..."
echo
echo
# This is for ADDING, if NOT ALREADY EXISTS, OR IS MULTI-VALUED.
#curl -k -H 'Accept:application/json' -k -u $USERNAME:$PASS -X POST https://$RPLMIHOST/wga/reverseproxy/$RPINSTANCE/configuration/stanza/server -d '{entries: [ ["network-interface", 10.20.139
.1]]}'

# Need to figure out how to pass RPIP variable into the curl syntax below.
curl -k -H "Content-Type: application/json" -H 'Accept:application/json' -k -u $USERNAME:$PASS -X PUT https://$RPLMIHOST/wga/reverseproxy/$NEWRPINSTANCE/configuration/stanza/server/entry_name
/network-interface -d "{'value':'$RPIP'}"
echo
echo

echo "NEW VALUE OF NETWORK-INTERFACE IS: "
curl -k -H 'Accept:application/json' -k -u $USERNAME:$PASS -X GET https://$RPLMIHOST/wga/reverseproxy/$RPINSTANCE/configuration/stanza/server/entry_name/network-interface
echo
echo
}

################################

function websealselfsignedcert ()
{
echo
echo "CREATING SELF-SIGNED WebSEAL CERTIFICATE..."
echo
echo
curl -k -H "Content-Type: application/json" -H 'Accept:application/json' -k -u $USERNAME:$PASS -X POST -d '{"operation":"generate","label":"WebSEAL-Test-Only","dn":"cn=webseal,o=ibm,c=us","ex
pire":"9999","default":"yes","size":"2048"}' https://$RPLMIHOST/isam/ssl_certificates/pdsrv/personal_cert

echo "PDSRV WebSEAL SELF-SIGNED CERTIFICATE DETAILS..."
curl -k -H 'Accept:application/json' -k -u $USERNAME:$PASS -X GET https://$RPLMIHOST/isam/ssl_certificates/pdsrv/personal_cert/WebSEAL-Test-Only
echo
echo
}

###############################

function ldapssl ()
{
echo
echo "UPDATING LDAP SSL SETTINGS..."
echo
echo
curl -k -H "Content-Type: application/json" -H 'Accept:application/json' -k -u $USERNAME:$PASS -X PUT -d '{"value":"yes"}' https://$RPLMIHOST/wga/reverseproxy/$RPINSTANCE/configuration/stanza
/ldap/entry_name/ssl-enabled

echo "NEW VALUE OF LDAP-SSL-ENABLED IS: "
curl -k -H 'Accept:application/json' -k -u $USERNAME:$PASS -X GET https://$RPLMIHOST/wga/reverseproxy/$RPINSTANCE/configuration/stanza/ldap/entry_name/ssl-enabled
echo
echo
}

###############################

function ldapsslkdb ()
{
echo
echo "UPDATING LDAP SSL KDB Settings..."
echo
echo
#curl -k -H "Content-Type: application/json" -H 'Accept:application/json' -k -u $USERNAME:$PASS -X PUT -d '{"value":"ldap_ssl.kdb"}' https://$RPLMIHOST/wga/reverseproxy/$RPINSTANCE/configurat
ion/stanza/ldap/entry_name/ssl-keyfile
curl -k -H "Content-Type: application/json" -H 'Accept:application/json' -k -u $USERNAME:$PASS -X PUT -d '{"value":"pdsrv.kdb"}' https://$RPLMIHOST/wga/reverseproxy/$RPINSTANCE/configuration/
stanza/ldap/entry_name/ssl-keyfile
curl -k -H "Content-Type: application/json" -H 'Accept:application/json' -k -u $USERNAME:$PASS -X PUT -d '{"value":"pdsrv"}' https://$RPLMIHOST/wga/reverseproxy/$RPINSTANCE/configuration/stan
za/ldap/entry_name/ssl-keyfile-pwd

echo "NEW VALUE OF LDAP-SSL IS: "
curl -k -H 'Accept:application/json' -k -u $USERNAME:$PASS -X GET https://$RPLMIHOST/wga/reverseproxy/$RPINSTANCE/configuration/stanza/ldap/entry_name/ssl-keyfile
echo
echo
}
###############################

function httpportsettings ()
{
echo
echo "UPDATING HTTP Settings..."
echo
echo
curl -k -H "Content-Type: application/json" -H 'Accept:application/json' -k -u $USERNAME:$PASS -X PUT -d '{"value":"no"}' https://$RPLMIHOST/wga/reverseproxy/$RPINSTANCE/configuration/stanza/
server/entry_name/http

echo "NEW VALUE OF LDAP-SSL IS: "
curl -k -H 'Accept:application/json' -k -u $USERNAME:$PASS -X GET https://$RPLMIHOST/wga/reverseproxy/$RPINSTANCE/configuration/stanza/server/entry_name/http
echo
echo
}

###############################

function httpsportsettings ()
{
echo
echo "UPDATING HTTPS-PORT Settings..."
echo
echo
curl -k -H "Content-Type: application/json" -H 'Accept:application/json' -k -u $USERNAME:$PASS -X PUT -d "{'value':'$HTTPSPORT'}" https://$RPLMIHOST/wga/reverseproxy/$RPINSTANCE/configuration
/stanza/server/entry_name/https-port
#curl -k -H "Content-Type: application/json" -H 'Accept:application/json' -k -u $USERNAME:$PASS -X PUT -d '{"value":"8443"}' https://$RPLMIHOST/wga/reverseproxy/$RPINSTANCE/configuration/stan
za/server/entry_name/https-port

echo "NEW VALUE OF HTTPS-PORT IS: "
curl -k -H 'Accept:application/json' -k -u $USERNAME:$PASS -X GET https://$RPLMIHOST/wga/reverseproxy/$RPINSTANCE/configuration/stanza/server/entry_name/https-port
echo
echo
}

###############################
# Update WebSEAL cert keyfile label settings.

function websealcertkeyfilelabel ()
{
echo
echo "UPDATING WEBSEAL-CERT-KEYFILE-LABEL Settings..."
echo
echo
curl -k -H "Content-Type: application/json" -H 'Accept:application/json' -k -u $USERNAME:$PASS -X PUT -d '{"value":"pdsrv.kdb"}' https://$RPLMIHOST/wga/reverseproxy/$RPINSTANCE/configuration/
stanza/ssl/entry_name/webseal-cert-keyfile

curl -k -H "Content-Type: application/json" -H 'Accept:application/json' -k -u $USERNAME:$PASS -X PUT -d '{"value":" "}' https://$RPLMIHOST/wga/reverseproxy/$RPINSTANCE/configuration/stanza/s
sl/entry_name/webseal-cert-keyfile-label

curl -k -H "Content-Type: application/json" -H 'Accept:application/json' -k -u $USERNAME:$PASS -X PUT -d '{"value":"pdsrv"}' https://$RPLMIHOST/wga/reverseproxy/$RPINSTANCE/configuration/stan
za/ssl/entry_name/webseal-cert-keyfile-pwd

#echo "NEW VALUE OF HTTPS-PORT IS: "
#curl -k -H 'Accept:application/json' -k -u $USERNAME:$PASS -X GET https://$RPLMIHOST/wga/reverseproxy/$RPINSTANCE/configuration/stanza/ssl/entry_name/webseal-cert-keyfile-label
echo
echo
}

###############################
# Update Non-Secure SSL  Settings.

function disableweakssl ()
{
echo
echo "UPDATING WEBSEAL-CERT-KEYFILE-LABEL Settings..."
echo
echo
curl -k -H "Content-Type: application/json" -H 'Accept:application/json' -k -u $USERNAME:$PASS -X PUT -d '{"value":"yes"}' https://$RPLMIHOST/wga/reverseproxy/$RPINSTANCE/configuration/stanza
/ssl/entry_name/disable-ssl-v2
curl -k -H "Content-Type: application/json" -H 'Accept:application/json' -k -u $USERNAME:$PASS -X PUT -d '{"value":"yes"}' https://$RPLMIHOST/wga/reverseproxy/$RPINSTANCE/configuration/stanza
/ssl/entry_name/disable-ssl-v3
curl -k -H "Content-Type: application/json" -H 'Accept:application/json' -k -u $USERNAME:$PASS -X PUT -d '{"value":"yes"}' https://$RPLMIHOST/wga/reverseproxy/$RPINSTANCE/configuration/stanza
/ssl/entry_name/disable-tls-v1
curl -k -H "Content-Type: application/json" -H 'Accept:application/json' -k -u $USERNAME:$PASS -X PUT -d '{"value":"yes"}' https://$RPLMIHOST/wga/reverseproxy/$RPINSTANCE/configuration/stanza
/ssl/entry_name/disable-tls-v11
curl -k -H "Content-Type: application/json" -H 'Accept:application/json' -k -u $USERNAME:$PASS -X PUT -d '{"value":"yes"}' https://$RPLMIHOST/wga/reverseproxy/$RPINSTANCE/configuration/stanza
/ssl/entry_name/disable-tls-v12

curl -k -H "Content-Type: application/json" -H 'Accept:application/json' -k -u $USERNAME:$PASS -X PUT -d '{"value":"yes"}' https://$RPLMIHOST/wga/reverseproxy/$RPINSTANCE/configuration/stanza
/junction/entry_name/disable-ssl-v2
curl -k -H "Content-Type: application/json" -H 'Accept:application/json' -k -u $USERNAME:$PASS -X PUT -d '{"value":"yes"}' https://$RPLMIHOST/wga/reverseproxy/$RPINSTANCE/configuration/stanza
/junction/entry_name/disable-ssl-v3
curl -k -H "Content-Type: application/json" -H 'Accept:application/json' -k -u $USERNAME:$PASS -X PUT -d '{"value":"yes"}' https://$RPLMIHOST/wga/reverseproxy/$RPINSTANCE/configuration/stanza
/junction/entry_name/disable-tls-v1
curl -k -H "Content-Type: application/json" -H 'Accept:application/json' -k -u $USERNAME:$PASS -X PUT -d '{"value":"yes"}' https://$RPLMIHOST/wga/reverseproxy/$RPINSTANCE/configuration/stanza
/junction/entry_name/disable-tls-v11
curl -k -H "Content-Type: application/json" -H 'Accept:application/json' -k -u $USERNAME:$PASS -X PUT -d '{"value":"yes"}' https://$RPLMIHOST/wga/reverseproxy/$RPINSTANCE/configuration/stanza
/junction/entry_name/disable-tls-v12
}

###############################
# Convert to unified object model (shared object space).

function sharedobjectspace ()
{
echo
echo "CONVERTING TO SHARED OBJECTSPACE..."
echo
echo
curl -k -H "Content-Type: application/json" -H 'Accept:application/json' -k -u $USERNAME:$PASS -X PUT -d "{'value':'$SHAREDOBJECTSPACE'}" https://$RPLMIHOST/wga/reverseproxy/$RPINSTANCE/confi
guration/stanza/server/entry_name/server-name
}


###############################
# Apply all changes and restart.

function applychangesrestart ()
{
echo
echo "APPLYING ALL CHANGES AND RESTART."
echo
echo
curl -k -H 'Accept:application/json' -k -u $USERNAME:$PASS -X PUT https://$RPLMIHOST/isam/pending_changes
echo
echo
curl -k -H 'Accept:application/json' -k -u $USERNAME:$PASS -X PUT https://$RPLMIHOST/wga/reverseproxy/$NEWRPINSTANCE -d '{"operation":"restart"}'
}
#################################
# Apply all changes and restart on NEW RP, WHEN DOING RP TO RP MIGRATION.

function applychangesrestarttwo ()
{
echo
echo "APPLYING ALL CHANGES AND RESTART."
echo
echo
curl -k -H 'Accept:application/json' -k -u $USERNAME:$PASS -X PUT https://$RPLMIHOST/isam/pending_changes
echo
echo
curl -k -H 'Accept:application/json' -k -u $USERNAME:$PASS -X PUT https://$RPLMIHOST/wga/reverseproxy/$NEWRPINSTANCE -d '{"operation":"restart"}'
}

#################################
### MAIN PROGRAM STARTS HERE
# Comment / uncomment the functions you want to execute / skip over.
clear
initializevariables
#createrpinstance
#exportisam9
#importisam9config
exporttam6
#importtam6config
# networkinterface
#websealselfsignedcert
# ldapssl
# ldapsslkdb
#httpportsettings
#httpsportsettings
#sharedobjectspace
# websealcertkeyfilelabel
# applychangesrestart
#applychangesrestarttwo
