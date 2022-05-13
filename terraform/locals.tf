locals {
  # General
  project_name = "lambda-vpc"
  project_tiers = {
    compute  = "compute"
    database = "database"
  }
  port_mappings = {
    https      = "443"
    postgresql = "5432"
  }

  # General AWS specific
  user_arn   = data.aws_caller_identity.this.arn
  account_id = data.aws_caller_identity.this.account_id
  azs        = ["${var.region}a", "${var.region}b", "${var.region}c"]

  # S3
  bucket_prefix = "${local.project_name}-"

  # Lambda
  lambda_role_name      = "${local.project_name}-role-"
  lambda_function_name  = "${local.project_name}-function"
  lambda_log_group_name = "/aws/lambda/${local.lambda_function_name}"

  # RDS
  db_identifier        = "${local.project_name}-db"
  db_subnet_group_name = "${local.project_name}-db-group"

  # Secrets
  db_password_secret_name = "db-password-"

  # Cloudwatch
  cw_rds_enhanced_monitoring_namespace                  = "RDS/EnhancedMonitoring"
  cw_rds_enhanced_monitoring_cpuutilization_metric_name = "RDSEnhancedMonitoringCPUUtilization"
  cw_rds_log_exports = {
    postgresql : "postgresql"
    upgrade : "upgrade"
  }

  # VPC
  compute_subnets_range  = range(0, 3) # 3 Compute Subnets
  database_subnets_range = range(3, 5) # 2 Database Subnets
  private_subnets_config = merge(
    {
      for index in local.compute_subnets_range : index => {
        az   = element(local.azs, index)
        cidr = cidrsubnet(var.vpc_cidr, 3, index)
        name = "${local.project_tiers.compute}-${substr(element(local.azs, index), -1, 1)}"
      }
    },
    {
      for index in local.database_subnets_range : index => {
        az   = element(local.azs, index)
        cidr = cidrsubnet(var.vpc_cidr, 3, index)
        name = "${local.project_tiers.database}-${substr(element(local.azs, index), -1, 1)}"
      }
    },
  )
}