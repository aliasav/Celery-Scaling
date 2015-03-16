##################### SCRIPT FOR SETTING UP SLEUTH AND CODEBASE SERVERS #####################

# This script does the following:
#	copies sleuth setup script into sleuth server
#	creates celery testing scripts in /tmp/celery
#	gets number of codebase servers
#	for each codebase server it does the following:
#		copies zabbix repo, setup script & mysql rpms
#		deploys code




# sleuth set-up 
echo -e "\n********************|| SLEUTH SERVER SETUP ||********************\n\n"
echo 'Enter sleuth server IP : '
read sleuth
# remove existing entry if any from ssh known hosts
ssh-keygen -f "/home/aliasav/.ssh/known_hosts" -R $sleuth
# copying zabbix agent repo to sleuth
scp /home/aliasav/COD/hod/ops/orchestration/app_install/zabbix_integration/agent/zabbix.repo  root@$sleuth:/etc/yum.repos.d/zabbix.repo
# copying server setup scripts to sleuth
scp /home/aliasav/COD/hod/hod_app/Celery-Scaling/servers-setup-scripts/sleuth_setup.sh root@$sleuth:/home/
sleep 2
echo -e "\n********************|| YOU MAY NOW SSH INTO SLEUTH SERVER $sleuth AND RUN THE SET UP SCRIPT ||********************\n\n"



# creating celery tests directory
rm -rf /tmp/celery
mkdir -p /tmp/celery
touch /tmp/celery/get_servers
get_servers=/tmp/celery/get_servers


echo -e "\n********************|| CODEBASE SERVER(s) SETUP ||********************\n\n"
# Getting path of COD Repo and mysql rmps
flag=0
# COD Repo
while [[ $flag -eq 0 ]]; do
	user=$USER
	echo "Enter absolute path of COD repository: "
	read path_to_repo
	path_to_hosts="$path_to_repo/ops/orchestration/app_install"
	cd $path_to_hosts -&>/dev/null
	if [ $? -eq 0 ]; then
		echo 'Correct path entered.'
		# test if COD_REPO already exists
		if grep -Fq "COD_REPO=" ~/.bashrc
		then
			sed -i '/export COD_REPO=/c\export COD_REPO='"$path_to_repo" ~/.bashrc
		else
			echo "export COD_REPO=$path_to_repo" >> ~/.bashrc
		fi
		break
	else
		echo 'Invalid path entered.'
		continue
	fi
done

flag=0
# mysql rpms
while [[ $flag -eq 0 ]]; do
	echo "Enter absolute path of MySQL rmps: "
	read path_to_mysql_rpms
	cd $path_to_mysql_rpms -&>/dev/null
	if [ $? -eq 0 ]; then
		echo 'Correct path entered.'
		flag=1
	else
		echo 'Invalid path entered.'
		continue
	fi
done



# codebase servers setup
echo 'Enter number of codebase servers: '
read n
echo "Servercount: $n" >> $get_servers
echo "IP addresses:" >> $get_servers



# taking servers IPs
for(( i=0; i<$n; i++ ))
do
	echo "Enter codebase server $i IP : "
	read codebase
	echo $codebase >> $get_servers
	# remove existing entry if any from ssh known hosts
	ssh-keygen -f "/home/aliasav/.ssh/known_hosts" -R $codebase
	
	echo -e "\n********************|| COPYING ZABBIX REPO AND SETUP SCRIPT INTO $codebase ||********************\n"
	# copying zabbix agent repo and setup script to codebase
	scp /home/aliasav/COD/hod/ops/orchestration/app_install/zabbix_integration/agent/zabbix.repo  root@$codebase:/etc/yum.repos.d/zabbix.repo
	scp /home/aliasav/COD/hod/hod_app/Celery-Scaling/servers-setup-scripts/codebase_setup.sh root@$codebase:/home/

	echo -e "\n********************|| COPYING MySQL RPMs INTO $codebase ||********************\n"
	# copying mysql rpms into server
	scp $path_to_mysql_rpms/MySQL-* root@$codebase:/tmp/

	echo -e "\n********************|| DEPLOYING CODE ON $codebase ||********************\n"
	# remove /etc/my.cnf
	ssh root@$codebase rm -f /etc/my.cnf 
	# deploying code into server
	touch /tmp/hosts
	path_to_hosts="$COD_REPO/ops/orchestration/app_install"
	sed '1!d' $path_to_hosts/hosts > /tmp/hosts
	echo $codebase >> /tmp/hosts
	ansible-playbook -i /tmp/hosts $path_to_hosts/app.yml --extra-vars "branch=feature/celery_study"
	rm -f /tmp/hosts

	echo -e "\n********************|| YOU MAY NOW SSH INTO CODEBASE$i SERVER $codebase AND RUN SETUP SCRIPT ||********************\n"
	sleep 2
done