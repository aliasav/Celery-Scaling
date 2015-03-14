###################### SLEUTH SETUP SCRIPT ######################

# This script does the following:
#	Installs basic utilities: wget, nano, bc, screen, zlib
#	Upgrades python version to Python 2.7.6 (since Sleuth is set up in Django 1.7)
#	Sets up iptables
#	Sets up zabbix and edits config file accordingly
#	Clones sleuth project, performs syncdb, migrate
#	Sets up gunicorn with start & stop scripts
# Run this script in the required server as 'root'.

echo "****************||Sleuth Setup||****************"


# installing basic utilities
echo "****************||Installing utilities : wget, nano, bc, screen, zlib, git, xz||****************"
yum -y install wget nano bc screen zlib git xz --nogpgcheck



# Python version upgrade
echo '****************||Upgrading Python version to Python 2.7.6||****************'
yum -y update --nogpgcheck
yum -y groupinstall "Development tools" --nogpgcheck
yum -y install zlib-devel bzip2-devel openssl-devel openssl-devel sqlite-devel --nogpgcheck
wget --no-check-certificate https://www.python.org/ftp/python/2.7.6/Python-2.7.6.tar.xz
tar xf Python-2.7.6.tar.xz
cd Python-2.7.6
./configure --prefix=/usr/local
make && make altinstall



# Installing pip
echo '****************||Installing pip||****************'
wget https://bitbucket.org/pypa/setuptools/raw/bootstrap/ez_setup.py
sudo /usr/local/bin/python2.7 ez_setup.py
sudo /usr/local/bin/easy_install-2.7 pip



# Setting up iptables
yum -y install iptables --nogpgcheck
echo '' > /etc/sysconfig/iptables
# here-doc for iptables
echo '****************||Setting Up iptables||****************'
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


# cloning sleuth repository in /home/
echo '****************||Cloning Sleuth||****************'
cd /home/
git clone git@bitbucket.org:healthondelivery/project-sleuth.git
cd /home/project-sleuth/
git checkout develop
pip install -r Requirements.txt
python2.7 manage.py syncdb
python2.7 manage.py migrate



# setting up gunicorn
cd /home/project-sleuth/
echo '****************||Setting Up gunicorn||****************'
pip install gunicorn



# creating gunicorn start script
touch gunicorn_start.sh
cat << EOF >> gunicorn_start.sh 
#!/bin/bash
echo "Starting Sleuth"
# Start your Django Unicorn
# Programs meant to be run under supervisor should not daemonize themselves (do not use --daemon)
exec gunicorn "sleuth".wsgi \
  --workers 10 \
  --timeout 10000 \
  --log-level=debug \
  --bind=0.0.0.0:8000  \
  --pid=/tmp/gunicorn.pid
  --error-logfile=/var/log/gunicorn_error.log
  --access-logfile=/var/log/gunicorn_access.log
EOF
chmod 777 gunicorn_start.sh 



# creating gunicorn stop script
touch gunicorn_stop.sh
cat << EOF >> gunicorn_stop.sh
#!/bin/bash
PID=$(cat /tmp/gunicorn.pid) # Read pid of gunicorn master process 
kill -15 $PID
EOF
chmod 777 gunicorn_stop.sh



# zabbix setup
echo '****************||Setting up Zabbix||****************'
scp /home/aliasav/COD/hod/ops/orchestration/app_install/zabbix_integration/agent/zabbix.repo  root@128.199.209.60:/etc/yum.repos.d/zabbix.repo
yum -y install zabbix-agent --nogpgcheck

# changing server IPs in /etc/zabbix/zabbix_agentd.conf
sed -i '/Server=127.0.0.1/c\Server=103.16.141.93' /etc/zabbix/zabbix_agentd.conf
sed -i '/ServerActive=127.0.0.1/c\#ServerActive=127.0.0.1' /etc/zabbix/zabbix_agentd.conf
service zabbix-agent restart



# creating screens
echo '****************||Creating screens: code, admin, proc||****************'
screen -Sdm gunicorn
screen -Sdm admin



# disable password authentication in /etc/ssh/sshd_config
echo '****************||Disabling PasswordAuthentication||****************'
sed -i '/PasswordAuthentication yes/c\PasswordAuthentication no' /etc/ssh/sshd_config
