

# Create AWS Secrets Manager secret
resource "aws_secretsmanager_secret" "cloud_re_devops" {
  name        = "cloud-sre-devops-secrets"
  description = "Secrets for Cloud Re DevOps API"
}

resource "aws_secretsmanager_secret_version" "cloud_re_devops" {
  secret_id = aws_secretsmanager_secret.cloud_re_devops.id
  secret_string = jsonencode({
    AUTH_URL      = var.auth_url
    DYNAMODB_TABLE = "cloudsredevops-ratings"
  })
}

# Create IAM role for Lambda
resource "aws_iam_role" "lambda_execution" {
  name = var.lambda_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Create IAM policy for Lambda to access Secrets Manager
resource "aws_iam_policy" "lambda_secrets_manager_access" {
  name = "lambda-secrets-manager-access"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = aws_secretsmanager_secret.cloud_re_devops.arn
      },
      {
        Effect = "Allow",
        Action = [
          "dynamodb:*"
        ],
        Resource = "*"
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

# Attach the policy to the Lambda execution role
resource "aws_iam_role_policy_attachment" "lambda_secrets_manager_access" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = aws_iam_policy.lambda_secrets_manager_access.arn
}

# Attach basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
