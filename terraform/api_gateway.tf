resource "aws_apigatewayv2_api" "http_api" {
  name          = "app-ratings-http-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.app_ratings.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "post_reviews" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_domain_name" "custom" {
  domain_name = "api.cloudsredevops.com"
  domain_name_configuration {
    certificate_arn = "arn:aws:acm:us-east-2:992382560483:certificate/978929ac-fb2e-4726-8a66-8055ecf70e9d"
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

resource "aws_apigatewayv2_api_mapping" "custom" {
  api_id      = aws_apigatewayv2_api.http_api.id
  domain_name = aws_apigatewayv2_domain_name.custom.domain_name
  stage       = aws_apigatewayv2_stage.default.name
} 

resource "aws_route53_record" "api_cname" {
  name    = aws_apigatewayv2_domain_name.custom.domain_name
  type    = "CNAME"
  zone_id = var.route53zoneid
  ttl     = 300
  records = [aws_apigatewayv2_domain_name.custom.domain_name_configuration[0].target_domain_name]
  
}

resource "aws_lambda_permission" "apigw_invoke" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.app_ratings.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/POST/"
}