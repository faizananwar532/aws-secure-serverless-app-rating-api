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

resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.lambda_name}-lambda-policy"
  role = aws_iam_role.lambda_exec.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:PutItem"
        ],
        Resource = aws_dynamodb_table.app_ratings.arn
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_lambda_function" "app_ratings" {
  filename         = "lambda_function.zip"
  function_name    = "${var.lambda_name}-lambda"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "app.lambda_handler"
  runtime          = "python3.9"
  timeout          = 10
  memory_size      = 128

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.app_ratings.name
    }
  }
} 
