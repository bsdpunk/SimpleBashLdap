# SimpleBashLdap
Ldapsearch and modify commands, broken down for ease of use
# Look at Caveats at the bottom
## To Use
Change The variables on lines 23 to 28 to match your ldap situation.

Source file
```
source ldap.sh
```
## Add Posix ability to users

For one user:
addposix ag03333 "Dusty Carver" 90025

Well that's cool but it barely saves me any time. Well what if you had to add a whole list of users to give POSIX too?

Good news, you can submit your updates as a csv, for example, I had this PDF with $var user on it, I just made a csv with:

uid,Full Name,gidNumber
IE:
```
c001222,"Sally Salazer",10692
c001444,"Isaiah Gatsby",10692
```
csv2posix userList.csv

Oh but wait sir, good sir, kind sir... What about verification of their name?


Well that's built in, if you have a big csv with uid,Full Name,gidNumber, guess what happens if the cn, IE normal name doesn't match? Well it throws you a prompt:
Current name ( ${NAME_FROM_CSV} ) is not in the Ldif information, Current Name is $NAME_FROM_RHDS  continue Y\\N:"

```
Current name ( "Jessica I Johnson" ) is not in the Ldif information, Current Name is cn: Jessica L. Johnson continue Y\N:
```

## Most Common Uses
addposix uid name group; getldap uid; csv2posix userList; 

Add a user to POSIX:
addtoposix 

# Caveats

Please check to make sure this is the same ldif you would use to add a user to POSIX:
```
dn: 'inserted through script'
add: objectClass
objectClass: posixAccount
-
add: uidNumber
uidNumber: 'inserted through script'
-
add: gidNumber
gidNumber: 'inserted through script'
-
add: homeDirectory
homeDirectory: /home/insertedThroughScript
-
add: loginShell
loginShell: /bin/bash
```
Please check to see if this is the same ldif, you would use for adding users to groups:
```
dn:'inserted by script'

changetype: modify
add: uniqueMember
uniqueMember:'insertedByScript'
```
## To Check What the LDIF file will look like With Inserts
```
Dustins-MacBook-Air:SimpleBashLdap dusty$ ldifPosixAdd uid "Real Name" gid
Dustins-MacBook-Air:SimpleBashLdap dusty$ ldifAddUserToGroup uid gidNumber
```
