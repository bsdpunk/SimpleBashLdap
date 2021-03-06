#!/bin/bash -
#===============================================================================
#
#          FILE: ldap.sh
#
#         USAGE: source ldap.sh; addposix uid name group; getldap uid; csv2posix userList 
#
#   DESCRIPTION: Simplify the ldapsearch and ldapmodify commands
#
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: All the bugs
#         NOTES: ---
#        AUTHOR: Dusty Carver,
#  ORGANIZATION:
#       CREATED: 05/ 2/2018 10:24
#      REVISION:  .4
#===============================================================================


OLD=$IFS

PASSWORD="" #yourPassword
HOST="" #ldapserver.example.com
PORT="" #389
BASE="" #dc=example,dc=com
BDN="" #cn=directory manager
MAGICNUMBER="" #Your magic number for generating new uidNumbers, DNA (Dynamic Number Assignment Plugin)

function dsrv() {

FQDN=$1

ldapsearch -v -x -H $HIST -D  $BDN -b $BASE -w $PASSWORD -s sub "nisNetgroupTriple=\($FQDN,-,\)" filter dn nisNetgroupTriple | grep cn= | sed 's/.*cn=//' | sed 's/,.*//'

}

 

function forGroup() { for i in $(cat $1);do dsrv $i ; dsrv $i ; done 2> /dev/null | sort | uniq ; }



function getGroup {
ldapsearch -D "$BDN" -w $PASSWORD -p $PORT -h $HOST -b "ou=groups,$BASE" -s sub "gidNumber=$1"
}

function getGroupId {
ldapsearch -D "$BDN" -w $PASSWORD -p $PORT -h $HOST -b $BASE -s sub "cn=$1"
}

function getNetGroupId {
ldapsearch -D "$BDN" -w $PASSWORD -p $PORT -h $HOST -b "ou=netgroup,$BASE" -s sub "cn=$1"
}

function isNetGroupName {

if getNetGroupId $1 | grep -q "nisnetgroup"; then
    getNetGroupId $1
else
    return 0
fi

}


function ldifPosixAdd() {

USER=$1
GID=$2
DN=$(getldap "${USER}" | grep "dn: uid")

echo "$DN"
echo "add: objectClass"
echo "objectClass: posixAccount"
echo "-"

echo "add: uidNumber"
echo "uidNumber: $MAGICNUMBER"
echo "-"

echo "add: gidNumber"
echo "gidNumber: $GID"
echo "-"

echo "add: homeDirectory"
echo "homeDirectory: /home/${USER}"
echo "-"

echo "add: loginShell"
echo "loginShell: /bin/bash"

}

function ldifAddUserToGroup() {

DN=$(getGroup "${2}" | grep "dn: cn")
USERID=$(getldap "${1}" | grep "dn: uid" | sed 's/^dn: //' )

echo "$DN"
echo "changetype: modify"
echo "add: uniqueMember"
echo "uniqueMember: $USERID"

}



function checkPosix {

if getldap "$1" | grep -q "posixAccount"; then
    echo "Account $1 has Posix"
    return 1
else
    return 0
fi 

}

function verifyName() {

if getldap "$1" | grep -q "$2"; then
    return 0
else
    return 1
fi

}

function addposix() {
local OPTIND
while getopts ":h" opt ; do
    case "$opt" in
        h )
            echo "addposix [-h] uid name group" 
            return 0
            ;;
        * )
            echo "invalid flag";
            ;;
    esac
done
if [[ -z $3 ]];
then
    echo "addposix takes 3 arguements, uid name group"
    echo "Ex: addposix uid \"Dusty Carver\" 11111"
    return
fi
int='^[0-9]+$'
if ! [[ $3 =~ $int ]] ;
then
    echo "Group ID must be integer, Did you not quote your name?"
    return
fi
if ! [[ -z $4 ]] ;
then
    echo "addposix only takes 3 arguements, uid name group"
    echo "Ex: addposix uid \"Dusty Carver\" 11111"
    return
fi
NUID=$1
NAME=$2
GROUP=$3
if checkPosix "$NUID" ; then
    if verifyName "$NUID" "$NAME" ; then
        ldapmodify -x -D "$BDN" -w $PASSWORD -H ldap://${HOST} -f <( ldifPosixAdd "${NUID}" "${GROUP}" )
    else
        echo "Current name ( ${NAME} ) is not in the Ldif information, Current Name is $( getldap "$NUID" | grep 'cn:' | head -n1)  continue Y\\N:"
        read -r ANS
        if [ "$ANS" == "Y" ];
        then
            ldapmodify -x -D "$BDN" -w $PASSWORD -H ldap://${HOST} -f <( ldifPosixAdd "${NUID}" "${GROUP}" )
        else
            echo "Mismatched Names, Not Sending, ${NUID}, ${NAME}"
        fi
    fi
else
    getldap "$1" ;
fi

}
function addtoldapgroup() {
        
local OPTIND
while getopts ":h" opt ; do
    case "$opt" in
        h )
            echo "addtoldapgroup [-h] uid gid" 
            return 0
            ;;
        * )
            echo "invalid flag";
            ;;
    esac
done
int='^[0-9]+$'
if ! [[ $2 =~ $int ]] ;
then
    echo "Group ID must be integer, EX: 90025"
    return
fi
if ! [[ -z $3 ]] ;
then
    echo "addtoldapgroup only takes 2 arguements, uid gid"
    echo "Ex: addposix ah03999 \"Dusty Carver\" 90025"
    return
fi

        ldapmodify -x -D $BDN -w $PASSWORD -H ldap://${HOST} -f <( ldifAddUserToGroup "${1}" "${2}" )
}


function csv2posix()
{
    FILE=$1
    local OPTIND
    while getopts ":h" opt ; do
        case "$opt" in
            h )
                echo "csv2posix [-h] target.csv" 
                return 0
                ;;
            * )
                echo "Invalid Flag"
                ;;
        esac
    done
    if [ $OPTIND -eq 1 ]; then
        IFS=$'\n';for i in $( cat $FILE);  do addposix $( awk -F, '{print $1}' <(echo $i)) $( awk -F, '{print $2}' <(echo $i)) $( awk -F, '{print $3}' <(echo $i)); done
        IFS=$OLD
    fi   
    shift $((OPTIND-1))

}

function getldap() { ldapsearch -D "$BDN" -w $PASSWORD -p $PORT -h $HOST -b $BASE -s sub "uid=$1"; }

function getuid() { ldapsearch -D "$BDN" -w $PASSWORD -p $PORT -h $HOST -b $BASE -s sub "uid=$1"| grep uidNumber | sed 's/uidNumber:[ ]\{0,\}//' ; }

function getusersfromou(){
ldapsearch -D "$BDN" -w $PASSWORD -p $PORT -h $HOST -b $BASE -LLL "(&(objectclass=*)(ou:dn:=${1}))" dn ;
}

function getalluserspa() {
ldapsearch -D "$BDN" -w $PASSWORD -p $PORT -h $HOST -b $BASE -LLL '(&(objectclass=posixAccount))' dn ;
}

function getexpiredusers(){
ldapsearch -D "$BDN" -w $PASSWORD -p $PORT -h $HOST -b $BASE -LLL "(&(objectclass=posixaccount)(ntUserAcctExpires=0))" dn ;
}
