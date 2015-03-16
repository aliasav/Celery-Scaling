###################### CODEBASE SETUP SCRIPT ######################

# This script sets up codebase server by installing basic utilities, setting up iptables, zabbix, screens, utility aliases.
# This script does the following:
#	Installs basic utilities: wget, nano, bc, screen.
#	Sets up iptables, screens
#	Sets up zabbix and edits config file accordingly
#	Sets up utility aliases
# Run this script in the required server as 'root'.


echo "****************|| CODEBASE SETUP ||****************"



# installing basic utilities
echo "****************|| INSTALLING UTILITIES : wget, nano, bc, screen, git||****************"
yum -y install wget nano bc screen git --nogpgcheck



# killing existing processes: celery, celerybeat, mysql (spawned by orchestration)
kill $(ps aux | grep 'celery' | awk '{print $2}')
monit stop celerybeat
monit stop celery
service mysql stop 



# creating blazecod.sh
echo '****************|| SETTING UP BLAZECOD ||****************'
touch /home/cod/workspace/blazecod.sh
# here doc for blazecod.sh
cat << EOF >> /home/cod/workspace/blazecod.sh
source /home/cod/workspace/envs/cod/bin/activate
cd /home/cod/workspace/development/cod/ 
EOF
chmod 777 /home/cod/workspace/blazecod.sh
# adding blazecod alias to /root/.bashrc
echo "#aliasav's aliases!" >> /root/.bashrc
echo "alias blazecod='source /home/cod/workspace/envs/cod/bin/activate'" >> /root/.bashrc



# Setting up iptables
yum -y install iptables --nogpgcheck
echo '' > /etc/sysconfig/iptables
# here-doc for iptables
echo '****************|| SETTING UP IPTABLES ||****************'
cat << EOF >> /etc/sysconfig/iptables
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A INPUT -p icmp -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A INPUT -m state --state NEW -m tcp -p tcp --dport 8000 -j ACCEPT 
-A INPUT -m state --state NEW -m tcp -p tcp --dport 10050 -j ACCEPT 
-A INPUT -m state --state NEW -m tcp -p tcp --dport 5555 -j ACCEPT 
-A INPUT -m state --state NEW -m tcp -p tcp --dport 22 -j ACCEPT
-A INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT
-A INPUT -m state --state NEW -m tcp -p tcp --dport 88 -j ACCEPT
-A INPUT -j REJECT --reject-with icmp-host-prohibited
-A FORWARD -j REJECT --reject-with icmp-host-prohibited
COMMIT
EOF
service iptables restart



# zabbix setup
echo '****************|| SETTING UP ZABBIX ||****************'
yum -y install zabbix-agent --nogpgcheck
# changing server IPs in /etc/zabbix/zabbix_agentd.conf
sed -i '/Server=127.0.0.1/c\Server=128.199.87.191' /etc/zabbix/zabbix_agentd.conf
sed -i '/ServerActive=127.0.0.1/c\#ServerActive=127.0.0.1' /etc/zabbix/zabbix_agentd.conf
service zabbix-agent restart



# creating screens
echo '****************|| CREATING SCREENS: code, admin, proc||****************'
screen -Sdm code
screen -Sdm admin
screen -Sdm proc



# disable password authentication in /etc/ssh/sshd_config
echo '****************|| DISABLING PasswordAuthentication IN SSH ||****************'
sed -i '/PasswordAuthentication yes/c\PasswordAuthentication no' /etc/ssh/sshd_config



# running syncdb and migrate
echo '****************|| RUNNING syncdb AND migrate ||****************'
source /home/cod/workspace/blazecod.sh
cd /home/cod/workspace/development/cod/hod_app/
python manage.py syncdb
python manage.py migrate
pip install celery --upgrade

sleep 2
echo -e '\n\n****************|| SERVER SETUP COMPLETE! ||****************'
echo -e '****************|| YOU MAY NOW START CELERY NODE ||****************'
echo -e '****************|| LUCIUS FOX IS BETTER THAN JARVIS! ||****************'


# setting up utility aliases
# here doc for /home/cod/.bashrc
cat << EOF >> /home/cod/.bashrc
# aliasav's aliases
alias taskcount='grep "Message" /home/cod/workspace/development/cod/hod_app/development.log|wc -l' 
alias clearlog='echo " " > /home/cod/workspace/development/cod/hod_app/development.log' 
alias celerystart='source /home/cod/workspace/development/cod/hod_app/Celery-Scaling/utility-scripts/start_celery_node.sh' 	
alias analysecelery='source /home/cod/workspace/development/cod/hod_app/Celery-Scaling/utility-scripts/individual_celery_analysis.sh' 
alias celerystop='source /home/cod/workspace/development/cod/hod_app/celery_stop.sh' 
alias blazecod='source /home/cod/workspace/blazecod.sh' 
alias howmanycelery='ps aux|grep celery|wc -l' 
EOF


echo -e '****************|| THIS SCRIPT WILL DELF_DESTRUCT IN 3! ||****************'
sleep 1
echo -e '****************|| 2... ||****************'
sleep 1
echo -e '****************|| 1... ||****************'
sleep 1
echo -e '****************|| GOODBYE ||****************'
rm -f /home/cod/codebase_setup.sh