variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default = "us-east-2"
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
  default = "prod"
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

variable "allowed_subdomains" {
  description = "List of allowed subdomains for CORS"
  type        = list(string)
  default = ["*"]
}

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

variable "terraform_state_bucket" {
  description = "S3 bucket name for Terraform state"
  type        = string
  default = "terraform-state-cloudsredevops"
}

variable "terraform_state_key" {
  description = "Key path for Terraform state file"
  type        = string
  default     = "api/terraform.tfstate"
}

variable "terraform_state_region" {
  description = "Region for Terraform state bucket"
  type        = string
  default     = "us-east-2"
} 