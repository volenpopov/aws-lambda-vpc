#!/bin/bash

lambda_function_name=$1

aws lambda invoke \
    --function-name ${lambda_function_name} \
    --cli-binary-format raw-in-base64-out \
    --payload '{"s3_object_key": "coffee.jpg"}' \
    $PROJECT_ROOT/lambda_invocation_response.json
