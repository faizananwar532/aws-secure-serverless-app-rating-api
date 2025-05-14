resource "aws_dynamodb_table" "app_reviews" {
  name           = "${local.name_prefix}-reviews"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "AppName"
  range_key      = "CreatedAtTimestamp"

  attribute {
    name = "AppName"
    type = "S"
  }

  attribute {
    name = "CreatedAtTimestamp"
    type = "N"
  }

  attribute {
    name = "CreatedAt"
    type = "S"
  }

  global_secondary_index {
    name            = "CreatedAtIndex"
    hash_key        = "CreatedAt"
    range_key       = "AppName"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = local.tags
} 