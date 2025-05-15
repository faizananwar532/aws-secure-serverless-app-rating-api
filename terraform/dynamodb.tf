resource "aws_dynamodb_table" "app_ratings" {
  name         = "${var.lambda_name}-ratings"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "AppName"
  range_key    = "CreatedAt"

  attribute {
    name = "AppName"
    type = "S"
  }

  attribute {
    name = "CreatedAt"
    type = "S"
  }
} 