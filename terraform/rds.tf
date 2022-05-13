resource "aws_iam_role" "rds_enhanced_monitoring" {
  name_prefix        = "${local.project_name}-rds-enhanced-monitoring-"
  assume_role_policy = file("${path.module}/policies/monitoring-rds-trust-policy.json")
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  role       = aws_iam_role.rds_enhanced_monitoring.name
  policy_arn = data.aws_iam_policy.rds_enhanced_monitoring.arn
}

resource "aws_db_instance" "this" {
  identifier = local.db_identifier

  engine         = "postgres"
  engine_version = "13.4"
  instance_class = "db.t3.micro"

  username = var.username
  password = var.db_password

  allocated_storage     = 5
  max_allocated_storage = 50

  multi_az = true

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  maintenance_window              = "Mon:00:00-Mon:03:00"
  backup_window                   = "03:00-06:00"
  enabled_cloudwatch_logs_exports = [local.cw_rds_log_exports.postgresql, local.cw_rds_log_exports.upgrade]

  monitoring_interval = 30
  monitoring_role_arn = aws_iam_role.rds_enhanced_monitoring.arn

  backup_retention_period = 0
  skip_final_snapshot     = true
}

##################################
# RDS Secrets
##################################
resource "aws_secretsmanager_secret" "password" {
  name_prefix = local.db_password_secret_name
}

resource "aws_secretsmanager_secret_policy" "password" {
  secret_arn = aws_secretsmanager_secret.password.arn

  policy = templatefile("${path.module}/policies/secrets-policy.json", {
    user_arn             = local.user_arn
    account_id           = local.account_id
    lambda_role_name     = aws_iam_role.lambda.id
    lambda_function_name = local.lambda_function_name
    secret_arn           = aws_secretsmanager_secret.password.arn
  })
}

resource "aws_secretsmanager_secret_version" "password" {
  secret_id     = aws_secretsmanager_secret.password.id
  secret_string = var.db_password
}

##################################
# RDS Monitoring
##################################
resource "aws_cloudwatch_log_metric_filter" "rds_high_cpu_utilization" {
  name           = local.cw_rds_enhanced_monitoring_cpuutilization_metric_name
  pattern        = "{ $.cpuUtilization.total >= 10 }"
  log_group_name = aws_cloudwatch_log_group.rds_enhanced_monitoring.name

  metric_transformation {
    name      = local.cw_rds_enhanced_monitoring_cpuutilization_metric_name
    namespace = local.cw_rds_enhanced_monitoring_namespace
    value     = "$.cpuUtilization.total"
    dimensions = {
      InstanceId = "$.instanceID"
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_high_cpu_utilization" {
  alarm_name          = aws_cloudwatch_log_metric_filter.rds_high_cpu_utilization.name
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = local.cw_rds_enhanced_monitoring_cpuutilization_metric_name
  namespace           = local.cw_rds_enhanced_monitoring_namespace
  period              = "120"
  statistic           = "Average"
  threshold           = "60"
  alarm_description   = "Average database CPU utilization is too high"

  dimensions = {
    InstanceId = aws_db_instance.this.id
  }
}

# Based on our config RDS will create the below log groups automatically,
# but adding them here ensures that they will get destroyed upon cleanup
resource "aws_cloudwatch_log_group" "postgresql_log_exports" {
  name = "/aws/rds/instance/${local.db_identifier}/${local.cw_rds_log_exports.postgresql}"
}
resource "aws_cloudwatch_log_group" "upgrade_log_exports" {
  name = "/aws/rds/instance/${local.db_identifier}/${local.cw_rds_log_exports.upgrade}"
}
resource "aws_cloudwatch_log_group" "rds_enhanced_monitoring" {
  name = "RDSOSMetrics"
}