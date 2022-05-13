#!/bin/bash

bucket_name=$1

aws s3 rm s3://${bucket_name} --recursive