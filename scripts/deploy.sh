#!/bin/bash

CURRENT_PATH=$(dirname "$0")
PROJECT_ROOT=$(cd "$CURRENT_PATH" && cd .. && pwd)

export PROJECT_ROOT

rm -rf $PROJECT_ROOT/build

mkdir $PROJECT_ROOT/build

cd $PROJECT_ROOT/function

echo "Installing lambda function dependencies..."

npm ci --production

cd $PROJECT_ROOT/terraform

terraform init

if [ -z "$TF_VAR_db_password" ]
then
      read -s -p "Enter database password: " TF_VAR_db_password
      
      echo -e "\nPassword set successfully"
      
      export TF_VAR_db_password
fi

tf_plan_file=$(echo $RANDOM | md5sum | head -c 20; echo;)

rm -rf $PROJECT_ROOT/terraform/execution_plan

mkdir $PROJECT_ROOT/terraform/execution_plan

terraform plan -out="$PROJECT_ROOT/terraform/execution_plan/$tf_plan_file"

terraform apply $PROJECT_ROOT/terraform/execution_plan/$tf_plan_file



