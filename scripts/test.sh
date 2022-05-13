#!/bin/bash

CURRENT_PATH=$(dirname "$0")
PROJECT_ROOT=$(cd "$CURRENT_PATH" && cd .. && pwd)

export PROJECT_ROOT

s3_object_key=coffee.jpg

cd $PROJECT_ROOT/terraform

bucket_name=$(terraform output --raw s3_bucket_name)
log_group_name=$(terraform output --raw lambda_log_group_name)
lambda_function_name=$(terraform output --raw lambda_function_name)

aws s3api head-object --bucket ${bucket_name} --key ${s3_object_key} || not_exist=true

if [ $not_exist ]
then
    $PROJECT_ROOT/scripts/helpers/uploadFileToBucket.sh ${bucket_name}
fi

$PROJECT_ROOT/scripts/helpers/invokeFunction.sh ${lambda_function_name}

sleep 2m

$PROJECT_ROOT/scripts/helpers/queryCloudwatchLogs.sh ${log_group_name}