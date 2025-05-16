resource "aws_iam_role" "lambda_exec" {
  name = "${var.lambda_name}-lambda-exec-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

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
