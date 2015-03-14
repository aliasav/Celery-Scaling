#### SCRIPT FOR INDIVIDUAL CELERY NODE TEST ANALYSIS ####

# This script does the following:
#	gets node settings
#	calculates time taken, tasks completed, effeciency, execution rate
#	 

# extract celery node settings from /tmp/celery_node_settings
w=$(awk 'NR==1{print $3}' /tmp/celery_node_settings)
c=$(awk 'NR==2{print $3}' /tmp/celery_node_settings)

echo -e "--------------CELERY TEST ANALYSIS------------------\n"
echo "Workers : "$w
echo "Concurrency :" $c

n=$(grep "Message" /home/cod/workspace/development/cod/hod_app/development.log|wc -l)
echo 'Number of tasks completed :' $n

# extracting start time and end time
start_time=$(awk 'NR==2{print $2}' /home/cod/workspace/development/cod/hod_app/development.log)
start_time=${start_time::8}
l=$(expr "$n" + 1)
end_time=$(awk -v l="$l" 'NR==l{print $2}' /home/cod/workspace/development/cod/hod_app/development.log)
end_time=${end_time::8}
echo 'Start Time: '$start_time
echo 'End Time  : '$end_time

# calculating execution time
s1=$(date --date="$start_time" +"%s")
e1=$(date --date="$end_time" +"%s")

total_time=$(expr "$e1" - "$s1")
execution_rate=$((n / total_time))
echo "Total time taken : $total_time seconds"
echo "Execution rate   : $execution_rate/s"
effeciency=$(awk -v e=$execution_rate -v w=$w -v c=$c 'BEGIN {print (e / (w * c))*100}')
echo "Effeciency     : "$effeciency
echo -e "\n ------------------------------------------------------------- \n"

# clear development.log
#echo " " > /home/cod/workspace/development/cod/hod_app/development.log
