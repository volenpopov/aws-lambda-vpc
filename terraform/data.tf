data "aws_region" "this" {}

data "aws_caller_identity" "this" {}

data "aws_iam_policy" "rds_enhanced_monitoring" {
  name = "AmazonRDSEnhancedMonitoringRole"
}

data "archive_file" "lambda" {
  type        = "zip"
  output_path = "${path.module}/../build/function.zip"
  source_dir  = "${path.module}/../function"
}
