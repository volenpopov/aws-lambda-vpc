#!/bin/bash

bucket_name=$1

cd $PROJECT_ROOT/images

aws s3api put-object --bucket ${bucket_name} --key coffee.jpg