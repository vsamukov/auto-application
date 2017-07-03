# auto-application

based on https://www.plesk.com/blog/autowordpress-plesk/

Install latest Plesk
Install Mysql 5.6 (i used Docker): https://support.plesk.com/hc/en-us/articles/213403429-How-to-upgrade-MySQL-5-5-to-5-6-5-7-on-Linux

Create service plan:

PHP 5.6, php mem_limit 512MB
Database mysql 5.6
Make sure PHP extensions "intl" and "soap" are present

download auto_magento.sh, put in /root/ on the server

create event handler, make it run "/root/auto_magento.sh" on event "Physical hosting provided"

in /root/auto_magento.sh make sure to put your plan name in TARGET_PLAN="Magento auto" variable
