# Cognito User Pool
resource "aws_cognito_user_pool" "main" {
  name = "${local.name_prefix}-user-pool"

  # Password policy
  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  # MFA configuration
  mfa_configuration = "OFF"

  # Admin create user config
  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  # Schema attributes
  schema {
    name                = "email"
    attribute_data_type = "String"
    mutable            = true
    required           = true

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  tags = local.tags
}

# Cognito User Pool Client
resource "aws_cognito_user_pool_client" "main" {
  name                         = "${local.name_prefix}-client"
  user_pool_id                = aws_cognito_user_pool.main.id
  generate_secret             = true
  refresh_token_validity      = 30
  prevent_user_existence_errors = "ENABLED"
  
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  callback_urls = [for subdomain in var.allowed_subdomains : "https://${subdomain}.${var.domain_name}"]
  logout_urls   = [for subdomain in var.allowed_subdomains : "https://${subdomain}.${var.domain_name}"]
  allowed_oauth_flows = ["code"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes = ["email", "openid", "profile"]
}

# Output the User Pool ID and Client ID
output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.main.id
}

output "cognito_client_id" {
  value = aws_cognito_user_pool_client.main.id
}

output "cognito_client_secret" {
  value     = aws_cognito_user_pool_client.main.client_secret
  sensitive = true
} 