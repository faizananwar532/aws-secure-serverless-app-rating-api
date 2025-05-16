resource "aws_lambda_function" "app_ratings" {
  filename         = "lambda_function.zip"
  function_name    = "${var.lambda_name}-lambda"
  role             = aws_iam_role.lambda_execution.arn
  handler          = "app.lambda_handler"
  runtime          = "python3.9"
  timeout          = 10
  memory_size      = 128

  # environment {
  #   variables = {
  #     DYNAMODB_TABLE = aws_dynamodb_table.app_ratings.name
  #     AUTH_URL = var.auth_url
  #     AUTH_URL_SECRET_NAME = "cloud-sre-devops-secrets"
  #   }
  # }
} 

