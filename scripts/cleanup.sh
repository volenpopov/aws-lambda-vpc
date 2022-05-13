#!/bin/bash

CURRENT_PATH=$(dirname "$0")
PROJECT_ROOT=$(cd "$CURRENT_PATH" && cd .. && pwd)

export PROJECT_ROOT

cd $PROJECT_ROOT/terraform

bucket_name=$(terraform output --raw s3_bucket_name)

$PROJECT_ROOT/scripts/helpers/emptyBucket.sh ${bucket_name}

terraform destroy -auto-approve
