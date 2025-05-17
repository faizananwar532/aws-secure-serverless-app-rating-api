# IP Set for allowed IPs
resource "aws_wafv2_ip_set" "allowed_ips" {
  name        = "allowed-ips"
  description = "Set of allowed IP addresses"
  scope       = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses = []  # Add specific allowed IPs here if needed
}

# IP Set for blocked IPs
resource "aws_wafv2_ip_set" "blocked_ips" {
  name        = "blocked-ips"
  description = "Set of blocked IP addresses"
  scope       = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses = []  # Add specific blocked IPs here if needed
}

# Regex pattern set for cloudsredevops.com subdomains
resource "aws_wafv2_regex_pattern_set" "cloudsre_domains" {
  name        = "cloudsre-domains"
  description = "Regex pattern for cloudsredevops.com subdomains"
  scope       = "CLOUDFRONT"

  regular_expression {
    regex_string = ".*\\.cloudsredevops\\.com"
  }

  tags = {
    Name = "cloudsre-domains"
  }
}

resource "aws_wafv2_web_acl" "cloudfront_acl" {
  name        = "cloudfront-waf-new"
  description = "WAF rules for CloudFront distribution"
  scope       = "CLOUDFRONT"

  default_action {
    block {}
  }

  rule {
    name     = "AllowCloudSreDevopsHosts"
    priority = 1
    action {
      allow {}
    }
    
    statement {
      or_statement {
        statement {
          byte_match_statement {
            field_to_match {
              single_header {
                name = "host"
              }
            }
            positional_constraint = "EXACTLY"
            search_string         = "api.cloudsredevops.com"
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }
        
        statement {
          regex_pattern_set_reference_statement {
            arn = aws_wafv2_regex_pattern_set.cloudsre_domains.arn
            field_to_match {
              single_header {
                name = "host"
              }
            }
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }
      }
    }
    
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AllowCloudSreDevopsHosts"
      sampled_requests_enabled   = true
    }
  }

  # Rule 2: AWS Managed Rules - Core ruleset to detect common web attacks
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 2
    
    override_action {
      count {}  # Use count instead of block to avoid blocking legitimate traffic
    }
    
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # Rule 3: SQL Injection Protection
  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 3
    
    override_action {
      none {}  # Block SQL injection attempts
    }
    
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }
    
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesSQLiRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # Rule 5: Rate-Based Rule - Block requests exceeding 1000 requests per minute
  rule {
    name     = "RateBasedRule"
    priority = 4
    
    action {
      block {}
    }
    
    statement {
      rate_based_statement {
        limit = 1000
        aggregate_key_type = "IP"
        
        scope_down_statement {
          and_statement {
            statement {
              ip_set_reference_statement {
                arn = aws_wafv2_ip_set.allowed_ips.arn
              }
            }
            statement {
              not_statement {
                statement {
                  ip_set_reference_statement {
                    arn = aws_wafv2_ip_set.blocked_ips.arn
                  }
                }
              }
            }
          }
        }
      }
    }
    
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateBasedRule"
      sampled_requests_enabled   = true
    }
  }

  # Rule 6: Block Suspicious User Agents
  rule {
    name     = "BlockSuspiciousUserAgents"
    priority = 5
    
    action {
      block {}
    }
    
    statement {
      or_statement {
        statement {
          byte_match_statement {
            field_to_match {
              single_header {
                name = "user-agent"
              }
            }
            positional_constraint = "CONTAINS"
            search_string         = "curl"
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }
        statement {
          byte_match_statement {
            field_to_match {
              single_header {
                name = "user-agent"
              }
            }
            positional_constraint = "CONTAINS"
            search_string         = "wget"
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }
        statement {
          byte_match_statement {
            field_to_match {
              single_header {
                name = "user-agent"
              }
            }
            positional_constraint = "CONTAINS"
            search_string         = "python-requests"
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }
      }
    }
    
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "BlockSuspiciousUserAgents"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "CloudfrontWAF"
    sampled_requests_enabled   = true
  }

  tags = {
    Name = "cloudfront-waf"
  }
}