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

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId               = "$context.requestId"
      ip                     = "$context.identity.sourceIp"
      requestTime            = "$context.requestTime"
      httpMethod             = "$context.httpMethod"
      routeKey               = "$context.routeKey"
      status                 = "$context.status"
      protocol               = "$context.protocol"
      responseLength         = "$context.responseLength"
      integrationError       = "$context.integrationErrorMessage"
      integrationLatency     = "$context.integrationLatency"
      integrationStatus      = "$context.integrationStatus"
      integrationRequestId   = "$context.integration.requestId"
      integrationErrorMessage = "$context.integrationErrorMessage"
      authorizerError        = "$context.authorizer.error"
      authorizerLatency      = "$context.authorizer.latency"
      authorizerStatus       = "$context.authorizer.status"
    })
  }
}

resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${aws_apigatewayv2_api.http_api.name}"
  retention_in_days = 30
}

resource "aws_lambda_permission" "apigw_invoke" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.app_ratings.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/POST/"
}