output "s3_bucket_name" {
  value = aws_s3_bucket.this.id
}

output "lambda_function_name" {
  value = local.lambda_function_name
}

output "lambda_log_group_name" {
  value = local.lambda_log_group_name
}