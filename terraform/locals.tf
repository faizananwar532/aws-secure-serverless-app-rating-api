locals {
  name_prefix = "devops-test-${var.environment}"
  tags = {
    Environment = var.environment
    Project     = "devops-test"
    ManagedBy   = "terraform"
  }
} 