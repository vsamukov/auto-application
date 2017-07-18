#!/bin/bash

TARGET_PLAN="Magento auto"

echo "--------------" >> /tmp/event_handler.log

/bin/date >> /tmp/event_handler.log # information on the event date and time

/usr/bin/id >> /tmp/event_handler.log # information on the user, on behalf of which the script was executed (to ensure control)


genpass_alphanum() {
        local l=$1
        [ "$l" == "" ] && l=16
        tr -dc A-Za-z0-9_ < /dev/urandom | head -c ${l} | xargs
}


genpass() {

        local l=$1
        [ "$l" == "" ] && l=16
        tr -dc A-Za-z0-9\_\!\@\#\$\%\^\&\*\?< /dev/urandom | head -c ${l} | xargs
}


##SELECTING LATEST MAGENTO APS PACKAGE VERSION AND ID



VER_RAW=(`plesk bin aps -gp|grep magento -A2 -B1|grep -v Vendor|grep -v Release|awk '{print $2}'`)

echo ${VER_RAW[*]}
VER_LEN=${#VER_RAW[*]}
VER=()
for i in {0,$((VER_LEN/3)),1}; do VER=(${VER[@]} ${VER_RAW[$((i*3-1))]}); done
IFS=$'\n' sorted=($(sort <<<"${VER[*]}"))
LVC=${#sorted[*]}
LATEST_VER=${sorted[$((LVC-1))]}
echo latest version is $LATEST_VER >>/tmp/event_handler.log
LATEST_PACKAGE_ID=`plesk bin aps -gp|grep $LATEST_VER -B3|head -1|awk '{print $2}'`
echo latest package id is $LATEST_PACKAGE_ID >>/tmp/event_handler.log

#LATEST_PACKAGE_ID=9


echo "domain ${NEW_DOMAIN_NAME}" >> /tmp/event_handler.log
echo "domain guid ${NEW_DOMAIN_GUID}"  >> /tmp/event_handler.log
echo "client guid ${NEW_CLIENT_GUID}" >> /tmp/event_handler.log

PLAN=`plesk bin site -i "${NEW_DOMAIN_NAME}"|grep -i plan|awk -F\" '{ print $2 }'`
#PLAN="WordPress auto"

echo $PLAN >> /tmp/event_handler.log

if [ "$PLAN" == "$TARGET_PLAN" ]; then
echo "${NEW_DOMAIN_NAME} is eligible for Magento installation" >> /tmp/event_handler.log

USER=`plesk bin domain -i $NEW_DOMAIN_NAME|grep Owner|awk -F\( '{print $2}'|awk -F\) '{print $1}'`
EMAIL=`plesk bin user -i $USER|grep mail|awk '{print $2}'`

echo $USER $EMAIL >> /tmp/event_handler.log

FNAME=`plesk bin user -i $USER|grep Contact|awk '{print $3}'`
LNAME=`plesk bin user -i $USER|grep Contact|awk '{print $4}'`

echo $FNAME >>/tmp/event_handler.log
echo $LNAME >>/tmp/event_handler.log

echo "installing Magent version $LATEST_VER package ID $LATEST_PACKAGE_ID for domain ${NEW_DOMAIN_NAME}" >> /tmp/event_handler.log
echo "generating secure password" >> /tmp/event_handler.log
PASSWD=`genpass 9`1_
echo "Password $PASSWD" >> /tmp/event_handler.log
echo "generating db name and db user name" >> /tmp/event_handler.log
DBUSER=admin_`genpass_alphanum 6`
echo "DB User $DBUSER" >> /tmp/event_handler.log
DBNAME=wp_`genpass_alphanum 6`
echo "DB Name $DBNAME" >> /tmp/event_handler.log



echo "Generating template for Magento" >> /tmp/event_handler.log


echo "<?xml version=\"1.0\"?>
<settings>
 <setting>
  <name>admin_email</name>
  <value>$EMAIL</value>
 </setting>
 <setting>
  <name>admin_firstname</name>
  <value>$FNAME</value>
 </setting>
 <setting>
  <name>admin_lastname</name>
  <value>$LNAME</value>
 </setting>
 <setting>
  <name>admin_name</name>
  <value>$NEW_SYSTEM_USER</value>
 </setting>
 <setting>
  <name>admin_password</name>
  <value>$PASSWD</value>
 </setting>
 <setting>
  <name>currency</name>
  <value>AUD</value>
 </setting>
 <setting>
  <name>locale</name>
  <value>en-US</value>
 </setting>
 <setting>
  <name>timezone</name>
  <value>Australia/Sydney</value>
 </setting>
</settings>" > /tmp/template1.xml


echo "plesk bin aps --install "/tmp/template1.xml" -package-id $LATEST_PACKAGE_ID -domain ${NEW_DOMAIN_NAME} -ssl false -url-prefix magento -db-name $DBNAME -db-user $DBUSER -passwd \"$PASSWD\" " >> /tmp/event_handler.log

plesk bin aps --install "/tmp/template1.xml" -package-id $LATEST_PACKAGE_ID -domain ${NEW_DOMAIN_NAME} -ssl false -url-prefix magento -db-name $DBNAME -db-user $DBUSER -passwd "$PASSWD" >> /tmp/event_handler.log 2>&1


echo "Finished installing magento for domain ${NEW_DOMAIN_NAME}" >> /tmp/event_handler.log
echo "Notifying user of successful installation" >> /tmp/event_handler.log
mail -s "Your Magento is ready" "$EMAIL" <<EOF
Hello, $USER.
Your Magento installation is ready.
To access it, open ${NEW_DOMAIN_NAME}/Magento
Login: $NEW_SYSTEM_USER
Password: $PASSWD
EOF


#rm /tmp/template1.xml -f

else echo  "${NEW_DOMAIN_NAME} does not need WP installation" >> /tmp/event_handler.log
fi

echo "--------------" >> /tmp/event_handler.log


