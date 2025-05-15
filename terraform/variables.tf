variable "aws_access_key" {
  description = "AWS access key"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS secret key"
  type        = string
  sensitive   = true
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default = "us-east-2"
}

variable "domain_name" {
  description = "Base domain name"
  type        = string
  default = "cloudsredevops.com"
}

variable "api_subdomain" {
  description = "Subdomain for the API"
  type        = string
  default     = "api"
}

variable "lambda_name" {
  description = "Lambda function name"
  type = string
  default = "cloudsredevops"
}
variable "route53zoneid" {
  sensitive = true
  description = "Route53 zone ID"
  type = string
}