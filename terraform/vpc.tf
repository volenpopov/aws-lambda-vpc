resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = local.project_name
  }
}

##################################
# Route Tables
##################################
resource "aws_default_route_table" "this" {
  default_route_table_id = aws_vpc.this.default_route_table_id

  tags = {
    Name = "${local.project_name}-main"
  }
}

resource "aws_route_table_association" "main" {
  for_each = { for index in local.database_subnets_range : index => index }

  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_default_route_table.this.id
}

resource "aws_route_table" "compute" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${local.project_name}-${local.project_tiers.compute}"
  }
}

resource "aws_route_table_association" "compute" {
  for_each = { for index in local.compute_subnets_range : index => index }

  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.compute.id
}

##################################
# Subnets
##################################
resource "aws_subnet" "private" {
  count = length(keys(local.private_subnets_config))

  vpc_id            = aws_vpc.this.id
  cidr_block        = lookup(local.private_subnets_config, count.index, null).cidr
  availability_zone = lookup(local.private_subnets_config, count.index, null).az

  tags = {
    Name = "${local.project_name}-${lookup(local.private_subnets_config, count.index, null).name}"
  }
}

resource "aws_db_subnet_group" "this" {
  name       = local.db_subnet_group_name
  subnet_ids = matchkeys(aws_subnet.private.*.id, keys(local.private_subnets_config), local.database_subnets_range)
}

##################################
# Security Groups
##################################
resource "aws_security_group" "lambda" {
  name        = "lambda"
  description = "Allow IPv4 EGRESS PostgreSQL to RDS, HTTPS S3 and HTTPS SecretsManager"
  vpc_id      = aws_vpc.this.id
}

resource "aws_security_group_rule" "lambda_egress_allow_https_s3" {
  type              = "egress"
  from_port         = local.port_mappings.https
  to_port           = local.port_mappings.https
  protocol          = "tcp"
  prefix_list_ids   = [aws_vpc_endpoint.s3.prefix_list_id]
  security_group_id = aws_security_group.lambda.id
}

resource "aws_security_group_rule" "lambda_egress_allow_postgresql" {
  type                     = "egress"
  from_port                = local.port_mappings.postgresql
  to_port                  = local.port_mappings.postgresql
  protocol                 = "tcp"
  security_group_id        = aws_security_group.lambda.id
  source_security_group_id = aws_security_group.rds.id
}

resource "aws_security_group_rule" "lambda_egress_allow_https_secretsmanager" {
  type                     = "egress"
  from_port                = local.port_mappings.https
  to_port                  = local.port_mappings.https
  protocol                 = "tcp"
  security_group_id        = aws_security_group.lambda.id
  source_security_group_id = aws_security_group.vpc_endpoint_secretsmanager.id
}

resource "aws_security_group" "rds" {
  name        = "postgresql"
  description = "Allow IPv4 PostgreSQL IN from Lambda"
  vpc_id      = aws_vpc.this.id
}

resource "aws_security_group_rule" "postgresql_ingress_allow_postgresql" {
  type                     = "ingress"
  from_port                = local.port_mappings.postgresql
  to_port                  = local.port_mappings.postgresql
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = aws_security_group.lambda.id
}

resource "aws_security_group" "vpc_endpoint_secretsmanager" {
  name        = "vpc_endpoint_secretsmanager"
  description = "Allow IPv4 HTTPS IN from Lambda"
  vpc_id      = aws_vpc.this.id
}

resource "aws_security_group_rule" "vpc_endpoint_ingress_allow_https" {
  type                     = "ingress"
  from_port                = local.port_mappings.https
  to_port                  = local.port_mappings.https
  protocol                 = "tcp"
  security_group_id        = aws_security_group.vpc_endpoint_secretsmanager.id
  source_security_group_id = aws_security_group.lambda.id
}

# ##################################
# # VPC Endpoints
# ##################################
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [aws_route_table.compute.id]

  tags = {
    Name = "${local.project_name}-s3-gateway-endpoint"
  }
}

resource "aws_vpc_endpoint" "secrets_manager" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${var.region}.secretsmanager"
  vpc_endpoint_type = "Interface"

  security_group_ids = [aws_security_group.vpc_endpoint_secretsmanager.id]
  subnet_ids         = matchkeys(aws_subnet.private.*.id, keys(local.private_subnets_config), local.compute_subnets_range)

  private_dns_enabled = true

  tags = {
    Name = "${local.project_name}-secretsmanager-endpoint"
  }
}