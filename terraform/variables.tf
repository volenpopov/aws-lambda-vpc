variable "username" {
  description = "The name of the database user."
  type        = string
  default     = "someuser"
}

variable "region" {
  description = "The AWS region in which the infrastructure will be deployed."
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "The VPC CIDR. It defines the range of available IP addresses within our custom network."
  type        = string
  default     = "10.16.0.0/25"
}

variable "db_password" {
  description = "The database password used for authentication with the database."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 8 && length(var.db_password) <= 50
    error_message = "The database password must be between 8 and 50 characters long."
  }
}
