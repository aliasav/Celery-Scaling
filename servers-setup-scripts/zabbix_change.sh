# Script to change zabbix IPs in zabbix conf files

echo -e "****************|| ZABBIX IPs CHANGE ||****************\n\n"
echo 'Enter number of servers to change zabbix IP in: '
read n
echo 'Enter old zabbix IP:'
read z1
echo -e '\nEnter new zabbix IP:'
read z2
echo -e "\n\n"
for (( i=1; i<=$n; i++ ))
do
	echo "Enter server $i IP:"
	read ip
	echo -e "****************|| Changing Zabbix IP from $z1 to $z2 in $ip ||****************\n\n"
	ssh root@$ip "sed -i '/Server=$z1/c\Server=$z2' /etc/zabbix/zabbix_agentd.conf"
	ssh root@$ip "service zabbix-agent restart"
	echo -e "\n\n"
done