###################### MULTIPLE CELERY NODES TESTING ANALYTICS ######################

# This script does the following:
#	gets development.log files from each server
#	gets number of workers and concurrency of each node
#	analyses individual celery node
#	analyses global process 

echo -e "-------------------|| MULTIPLE CELERY NODES TESTING : ANALYSIS ||-------------------\n"

# get server count
n=$(awk 'NR==1{print $2}' /tmp/celery/get_servers)

# scp into servers and get development.log and celery_nodes_settings files
mkdir -p /tmp/celery/logfiles
mkdir -p /tmp/celery/celery_nodes_settings_files
logs=/tmp/celery/logfiles
nodes=/tmp/celery/celery_nodes_settings_files
get_servers=/tmp/celery/get_servers
for (( i=0; i<$n; i++ ))
do
	l=$(( 3 + $i ))
	ip=$(sed -e $l'q;d' $get_servers)
	scp root@$ip:/home/cod/workspace/development/cod/hod_app/development.log $logs/"dev$i".log
	scp root@$ip:/tmp/celery_node_settings $nodes/"node$i"
done

# set permissions of tmp files
chmod 777 $logs/*
chmod 777 $nodes/*

# populate worker and concurrency arrays
for (( i=0; i<$n; i++ ))
do
	workers[$i]=$(awk 'NR==1{print $3}' "$nodes"/"node$i")
	concurrency[$i]=$(awk 'NR==2{print $3}' "$nodes"/"node$i")
done
echo -e "\n\n"
# display individual node analysis and populate start time, end time, total time, execution rates, tasks completed, effeciency arrays
for (( i=0; i<$n; i++ ))
do
	# get information
	w=${workers[$i]}
	c=${concurrency[$i]}
	t=$(grep "Message" "$logs"/"dev$i".log|wc -l)
	l=$(( 3 + $i ))
	ip=$(sed -e $l'q;d' $get_servers)

	# datetime format times
	start_time=$(awk 'NR==2{print $2}' "$logs"/"dev$i".log)
	start_time=${start_time::8}
	l=$(expr "$t" + 1)
	x=$(awk 'END{print}' /tmp/celery/logfiles/dev"$i".log)
	end_time=$(echo $x|awk '{print $2}')
	end_time=${end_time::8}
	# times from epoch
	s1=$(date --date="$start_time" +"%s")
	e1=$(date --date="$end_time" +"%s")
	total_time=$(expr "$e1" - "$s1")

	# rates
	execution_rate=$(( t / total_time ))
	effeciency=$(awk -v e=$execution_rate -v w=$w -v c=$c 'BEGIN {print (e / (w * c))*100}')

	# populate arrays
	start_time_array[$i]=$s1
	end_time_array[$i]=$e1
	total_time_array[$i]=$total_time
	tasks_completed_array[$i]=$t
	effeciency_array[$i]=$effeciency
	execution_rate_array[$i]=$execution_rate
	total_processes[$i]=$(( w * c ))

	# Display individual node information
	echo -e "-------------------||NODE $i ($ip) : ANALYSIS||-------------------\n\n"
	echo "Workers             : "$w
	echo "concurrency         : "$c
	echo "Tasks completed     : "$t
	echo "Time taken          : "$total_time
	echo "Task execution rate : "$execution_rate
	echo "Effeciency          : "$effeciency
	echo -e "\n\n"
done

# calculate global information

global_start_time=0 
for i in ${start_time_array[@]}; 
do
    (( $i < global_start_time || global_start_time == 0)) && global_start_time=$i
done

global_end_time=0 
for i in ${end_time_array[@]}; 
do
    (( $i > global_end_time || global_end_time == 0)) && global_end_time=$i
done

global_total_time=$(expr "$global_end_time" - "$global_start_time")

global_total_tasks=0
average_execution_rate=0
average_effeciency=0
global_workers=0
global_total_processes=0
for (( i=0; i<$n; i++ ))
do
	global_total_tasks=$(expr "$global_total_tasks" + "${tasks_completed_array[$i]}")
	average_execution_rate=$(expr "$average_execution_rate" + "${execution_rate_array[$i]}")
	global_workers=$(expr "$global_workers" + "${workers[$i]}")
	global_total_processes=$(expr "$global_total_processes" + "${total_processes[$i]}")
done

average_execution_rate=$(awk -v a=$average_execution_rate -v n=$n 'BEGIN {print ( a / n )}')

global_execution_rate=$(( global_total_tasks / global_total_time ))
global_effeceincy=$(awk -v e=$global_execution_rate -v g=$global_total_processes 'BEGIN {print (( e / g )*100)}' )
effeciency=$(awk -v e=$execution_rate -v w=$w -v c=$c 'BEGIN {print (e / (w * c))*100}')

# display global analysis
echo -e "-------------------||GLOBAL NODE ANALYSIS||-------------------\n\n"
echo "Total Workers                 : "$global_workers
echo "Total celery processes        : "$global_total_processes
echo "Total Tasks completed         : "$global_total_tasks
echo "Total Time taken              : "$global_total_time
echo "Task execution rate           : "$global_execution_rate
echo "Effeciency                    : "$global_effeceincy
echo "Average task execution rate   : "$average_execution_rate

echo -e "\n-----------------------||TEST ANALYTICS COMPLETED||-----------------------\n"

# clear log files in servers
for (( i=0; i<$n; i++ ))
do
	l=$(( 3 + $i ))
	ip=$(sed -e $l'q;d' $get_servers)
	ssh root@$ip 'echo " " > /home/cod/workspace/development/cod/hod_app/development.log'

done

# clean up tmp files
rm -f /tmp/celery/logfiles/*
rm -f /tmp/celery/celery_nodes_settings_files/*
