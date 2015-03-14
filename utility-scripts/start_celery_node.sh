##################### SCRIPT FOR STARTING CELERY NODE #####################

# This script does the following:
#	starts celery instance by taking input(workers, concurrency) from user
#	creates /tmp/celery_node_settings which is used by analyse script and mined for multiple nodes test analytics 

echo '-------------------------|| STARTING CELERY NODE ||-------------------------'

# clear development.log
echo '' > /home/cod/workspace/development/cod/hod_app/development.log

# take concurrency and number of workers from user
c=0
n=0
echo 'Enter number of workers: '
read n
echo 'Enter concurrency: '
read c

LOGFILE=/var/log/celery.log

# preparing celery_stop.sh
echo '-------------------------|| PREPARING celery_stop.sh ||-------------------------'
rm -f /home/cod/workspace/development/cod/hod_app/celery_stop.sh
touch /home/cod/workspace/development/cod/hod_app/celery_stop.sh
# here doc for /home/cod/workspace/development/cod/hod_app/celery_stop.sh
cat << EOF >> /home/cod/workspace/development/cod/hod_app/celery_stop.sh
python manage.py celery multi stop $n -l INFO -c $c --logfile=$LOGFILE --app=hod_app.celery.cod
rm -f /tmp/celery_node_settings
rm -f /tmp/
EOF



# creating temporary file with node settings for analyse script and multiple node analytics
touch /tmp/celery_node_settings
chmod 777 /tmp/celery_node_settings
echo "w = $n" > /tmp/celery_node_settings
echo "c = $c" >> /tmp/celery_node_settings



# starting celery node
cd /home/cod/workspace/development/cod/hod_app/
source /home/aliasav/COD/virtualenvs/cod/bin/activate
python manage.py celery multi start $n -l INFO -c $c --logfile=$LOGFILE  --pidfile=/tmp/celery%n.pid --app=hod_app.celery.cod -Ofair
echo "-------------------------|| WHEN DONE, KILL NODE USING 'celerystop' ||-------------------------"