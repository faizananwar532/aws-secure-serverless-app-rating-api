# resource "aws_wafv2_regex_pattern_set" "allowed_domains" {
#   name        = "allowed-cloudsredevops-domains"
#   description = "Allow only subdomains of cloudsredevops.com"
#   scope       = "REGIONAL"

#   regular_expression {
#     regex_string = "https?://([a-zA-Z0-9-]+\\.)*cloudsredevops\\.com"
#   }
# }

# resource "aws_wafv2_web_acl" "api_acl" {
#   name        = "api-waf"
#   description = "WAF for API Gateway to allow only subdomains of cloudsredevops.com and block malicious requests"
#   scope       = "REGIONAL"

#   default_action {
#     block {}
#   }

#   rule {
#     name     = "AllowCloudsredevopsSubdomains"
#     priority = 1
#     action {
#       allow {}
#     }
#     statement {
#       regex_pattern_set_reference_statement {
#         arn = aws_wafv2_regex_pattern_set.allowed_domains.arn
#         field_to_match {
#           single_header {
#             name = "origin"
#           }
#         }
#         text_transformation {
#           priority = 0
#           type     = "NONE"
#         }
#       }
#     }
#     visibility_config {
#       cloudwatch_metrics_enabled = true
#       metric_name                = "AllowCloudsredevopsSubdomains"
#       sampled_requests_enabled   = true
#     }
#   }

#   rule {
#     name     = "AWSManagedRulesCommonRuleSet"
#     priority = 2
#     override_action {
#       none {}
#     }
#     statement {
#       managed_rule_group_statement {
#         name        = "AWSManagedRulesCommonRuleSet"
#         vendor_name = "AWS"
#       }
#     }
#     visibility_config {
#       cloudwatch_metrics_enabled = true
#       metric_name                = "AWSManagedRulesCommonRuleSet"
#       sampled_requests_enabled   = true
#     }
#   }

#   visibility_config {
#     cloudwatch_metrics_enabled = true
#     metric_name                = "apiWAF"
#     sampled_requests_enabled   = true
#   }
# }

# resource "aws_wafv2_web_acl_association" "api_acl_assoc" {
#   resource_arn = aws_apigatewayv2_stage.default.arn
#   web_acl_arn  = aws_wafv2_web_acl.api_acl.arn
# }