terraform {
  backend "s3" { 
    bucket         = "terraform-state-cloudsredevops"
    key            = "terraform.tfstate"
    region         = "us-east-2"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

# DynamoDB table for state locking
resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = "terraform-state-lock"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform State Lock Table"
    Environment = var.environment
  }
} 