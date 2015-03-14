# This script does the following:
#	gets number of celery servers
#	gets IPs of each servers

echo -e "-------------------||MULTIPLE CELERY NODES TESTING : SETUP||-------------------\n"

mkdir -p /tmp/celery
touch /tmp/celery/get_servers
get_servers=/tmp/celery/get_servers
echo "Enter number of servers: "
read n
echo "Servercount: $n" >> $get_servers

echo -e "IP addresses:" >> $get_servers
# taking servers IPs
for (( i=0; i<$n; i++ ))
do
	echo "Enter IP of server $i:" 
	read ip 
	echo $ip >> $get_servers
done