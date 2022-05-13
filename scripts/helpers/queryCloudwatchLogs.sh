#!/bin/bash

log_group_name=$1

declare -i start_time
declare -i end_time
declare -i last_minutes
declare -i last_millis

end_time=$(date +%s)
last_minutes=3
last_millis=$last_minutes*60*1000
start_time=$end_time-$last_millis

query_id=$(aws logs start-query --log-group-name $log_group_name --start-time $start_time --end-time $end_time --query-string "fields @timestamp, @message | sort @timestamp desc" | jq -r '.queryId')

aws logs get-query-results --query-id $query_id | jq '.results[][].value' | grep Successfully
