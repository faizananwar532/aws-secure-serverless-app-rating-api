# Lambda function
resource "aws_lambda_function" "app_review_api" {
  filename         = "../lambda_function.zip"
  function_name    = "${local.name_prefix}-api"
  role            = aws_iam_role.lambda_role.arn
  handler         = "app.lambda_handler"
  runtime         = "python3.9"
  timeout         = 30
  memory_size     = 256

  environment {
    variables = {
      DYNAMODB_TABLE        = aws_dynamodb_table.app_reviews.name
      COGNITO_USER_POOL_ID = aws_cognito_user_pool.main.id
      COGNITO_CLIENT_ID    = aws_cognito_user_pool_client.main.id
      LOG_LEVEL           = "INFO"
      DOMAIN_NAME         = var.domain_name
      ALLOWED_SUBDOMAINS  = join(",", var.allowed_subdomains)
    }
  }

  tags = local.tags
}

# REST API Gateway
resource "aws_api_gateway_rest_api" "api" {
  name        = "${local.name_prefix}-api"
  description = "REST API for app reviews"
}

resource "aws_api_gateway_resource" "reviews" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "reviews"
}

resource "aws_api_gateway_method" "post_review" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.reviews.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.reviews.id
  http_method = aws_api_gateway_method.post_review.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.app_review_api.invoke_arn
}

resource "aws_api_gateway_deployment" "api" {
  depends_on = [aws_api_gateway_integration.lambda]
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = var.environment
}

resource "aws_api_gateway_stage" "api" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = var.environment
  deployment_id = aws_api_gateway_deployment.api.id
}

resource "aws_api_gateway_domain_name" "api" {
  domain_name = "${var.api_subdomain}.${var.domain_name}"
  regional_certificate_arn = aws_acm_certificate_validation.api.certificate_arn
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_base_path_mapping" "api" {
  api_id      = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_stage.api.stage_name
  domain_name = aws_api_gateway_domain_name.api.domain_name
}

# CloudWatch Logs
resource "aws_cloudwatch_log_group" "api_logs" {
  name              = "/aws/apigateway/${local.name_prefix}"
  retention_in_days = 30
}

# WAF rules for security
resource "aws_wafv2_web_acl" "api" {
  name        = "${local.name_prefix}-waf"
  description = "WAF rules for API protection"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  # Rule to restrict requests to allowed subdomains
  rule {
    name     = "RefererDomainRestriction"
    priority = 1

    action {
      block {}
    }

    statement {
      regex_match_statement {
        regex_string = "https?://api\\.cloudsredevops\\.com"
        field_to_match {
          single_header {
            name = "referer"
          }
        }
        text_transformation {
          priority = 0
          type     = "NONE"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RefererDomainRestriction"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "RateLimit"
    priority = 2

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name               = "RateLimit"
      sampled_requests_enabled  = true
    }
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name               = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled  = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name               = "APIGatewayWAF"
    sampled_requests_enabled  = true
  }
}

# WAF Regex Pattern Set for allowed domains
resource "aws_wafv2_regex_pattern_set" "allowed_domains" {
  name        = "${local.name_prefix}-allowed-domains"
  description = "Regex pattern set for allowed domains"
  scope       = "REGIONAL"

  dynamic "regular_expression" {
    for_each = var.allowed_subdomains
    content {
      regex_string = "https?://${regular_expression.value}\\.${var.domain_name}"
    }
  }

  tags = local.tags
}

resource "aws_wafv2_web_acl_association" "api" {
  resource_arn = aws_api_gateway_stage.api.arn
  web_acl_arn  = aws_wafv2_web_acl.api.arn
}

output "rest_api_id" {
  value = aws_api_gateway_rest_api.api.id
} 