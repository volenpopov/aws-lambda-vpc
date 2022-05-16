resource "aws_iam_role" "lambda" {
  name_prefix        = local.lambda_role_name
  assume_role_policy = file("${path.module}/policies/lambda-trust-policy.json")
}

resource "aws_iam_policy" "lambda" {
  name_prefix = "${local.project_name}-permissions-"
  description = "A policy containing all the required permissions for our lambda function"

  policy = templatefile("${path.module}/policies/lambda-permissions-policy.json", {
    account_id     = local.account_id
    bucket_name    = aws_s3_bucket.this.id
    region         = data.aws_region.this.name
    log_group_name = local.lambda_log_group_name
    secret_arn     = aws_secretsmanager_secret.password.arn
  })
}

resource "aws_iam_role_policy_attachment" "lambda" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda.arn
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = local.lambda_log_group_name
  retention_in_days = 7
}

resource "aws_lambda_function" "this" {
  filename      = data.archive_file.lambda.output_path
  function_name = local.lambda_function_name
  role          = aws_iam_role.lambda.arn
  handler       = "handler/index.handler"

  source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime = "nodejs14.x"

  vpc_config {
    subnet_ids         = matchkeys(aws_subnet.private.*.id, keys(local.private_subnets_config), local.compute_subnets_range)
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      DB_HOST                             = aws_db_instance.this.address
      DB_PORT                             = local.port_mappings.postgresql
      DB_USER                             = var.username
      DB_PASSWORD_SECRET_NAME             = aws_secretsmanager_secret.password.name
      BUCKET_NAME                         = aws_s3_bucket.this.id
      AWS_NODEJS_CONNECTION_REUSE_ENABLED = 1
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda]
}
