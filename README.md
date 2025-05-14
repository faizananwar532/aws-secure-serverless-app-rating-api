# DevOps Test API

## Overview
This project implements a secure, serverless API for collecting app reviews. It uses AWS Lambda (Python), API Gateway REST API, DynamoDB, Cognito for authentication, and WAF for security. The API is accessible at `https://api.cloudsredevops.com/reviews` and only allows requests from subdomains of `cloudsredevops.com`.

## Features
- Accepts HTTPS POST requests with parameters: `AppName` (string, max 50 chars), `Rating` (1-5), `Description` (string, max 2000 chars)
- Authenticates requests using Cognito JWT tokens
- Only allows requests from allowed subdomains (CORS and WAF)
- Stores data in DynamoDB for fast retrieval by AppName and create date
- Logs application events to CloudWatch
- Uses AWS WAF for security (rate limiting, referer restriction, managed rules)
- Fully serverless, highly available, and cost-efficient

## API Usage
### Endpoint
```
POST https://api.cloudsredevops.com/reviews
```

### Request Headers
- `Content-Type: application/json`
- `Authorization: Bearer <JWT_TOKEN>` (from Cognito)
- `Origin: https://api.cloudsredevops.com` (or another allowed subdomain)

### Request Body
```
{
  "AppName": "MyApp",
  "Rating": 5,
  "Description": "Great application!"
}
```

### Example curl Command
```
curl -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <JWT_TOKEN>" \
  -H "Origin: https://api.cloudsredevops.com" \
  -d '{"AppName": "MyApp", "Rating": 5, "Description": "Great application!"}' \
  https://api.cloudsredevops.com/reviews
```

## Security
- **CORS**: Only allows requests from allowed subdomains of `cloudsredevops.com`.
- **WAF**: Protects against malicious requests, rate limits, and restricts referer headers.
- **Authentication**: Uses AWS Cognito JWT tokens.

## Deployment
See `GETTING_STARTED.md` for full deployment instructions using Terraform and GitLab CI/CD.

## Architecture Overview

The solution consists of:
- AWS Lambda function (Python) for handling API requests
- Amazon API Gateway for HTTP endpoint management
- Amazon DynamoDB for data storage
- AWS WAF for security
- CloudWatch for logging and monitoring
- Custom domain with SSL certificate
- GitLab CI/CD pipeline for automated deployment

## Features

- Secure HTTPS endpoint with custom domain
- Token-based authentication
- Origin validation for cloudsredevops.com subdomains
- Input validation and constraints
- Fast data retrieval using DynamoDB indexes
- Comprehensive logging
- Rate limiting and security rules
- Automated deployment pipeline

## Infrastructure as Code (Terraform)

The infrastructure is managed using Terraform with the following structure:

```
terraform/
├── main.tf           # Main configuration and provider settings
├── variables.tf      # Variable declarations
├── api.tf           # API Gateway and Lambda configuration
├── dynamodb.tf      # DynamoDB table configuration
├── iam.tf           # IAM roles and policies
├── input.tfvars # Default variable values
└── .gitignore      # Git ignore rules
```

### Variable Management

The project uses a secure approach to variable management:

1. **Non-sensitive variables** (`input.tfvars`):
   ```hcl
   aws_region = "us-east-1"
   environment = "prod"
   domain_name = "api.cloudsredevops.com"
   ```

2. **Sensitive variables** (`secrets-input.tfvars` - git-ignored):
   ```hcl
   aws_access_key = "YOUR_AWS_ACCESS_KEY"
   aws_secret_key = "YOUR_AWS_SECRET_KEY"
   token_validation_endpoint = "YOUR_TOKEN_VALIDATION_ENDPOINT"
   ```

3. **Environment-specific variables**:
   - Create separate .tfvars files for each environment (e.g., `dev.tfvars`, `prod.tfvars`)
   - Pass sensitive variables through CI/CD

### Security Features

1. **WAF Protection**:
   - Rate limiting (2000 requests per IP)
   - Domain restriction to cloudsredevops.com subdomains
   - AWS Managed Rules for common attack patterns
   - SQL injection protection
   - XSS protection
   - Path traversal protection

2. **Access Control**:
   - IAM role-based access
   - Token-based authentication
   - Origin validation
   - HTTPS encryption

3. **Monitoring**:
   - CloudWatch Logs
   - WAF metrics
   - API Gateway access logs
   - Lambda function logs

## Advantages

1. **Cost Efficiency**:
   - Pay-per-use pricing model with Lambda and DynamoDB
   - No idle resources or maintenance costs
   - Automatic scaling based on demand

2. **High Availability**:
   - Multi-AZ deployment by default
   - No single point of failure
   - Automatic failover

3. **Security**:
   - HTTPS encryption
   - WAF protection against common attacks
   - Rate limiting
   - Origin validation
   - Token-based authentication
   - IAM role-based access control

4. **Performance**:
   - Fast response times with Lambda
   - Optimized DynamoDB table design for quick queries
   - Global secondary indexes for efficient data retrieval

5. **Maintainability**:
   - Infrastructure as Code with Terraform
   - Automated deployment pipeline
   - Centralized logging and monitoring
   - Easy to update and scale

## Disadvantages

1. **Cold Start Latency**:
   - Lambda functions may experience cold starts
   - Initial request might be slower

2. **Cost at Scale**:
   - While cost-efficient for low to medium traffic
   - Can become expensive with very high traffic
   - DynamoDB costs increase with data size and read/write capacity

3. **Vendor Lock-in**:
   - Solution is tightly coupled with AWS services
   - Migration to another cloud provider would require significant changes

4. **Complexity**:
   - Multiple AWS services to manage
   - Requires understanding of various AWS services
   - More complex than a traditional monolithic application

5. **Debugging Challenges**:
   - Distributed nature makes debugging more complex
   - Need to check multiple services for issues
   - Requires good logging and monitoring setup

## Monitoring

- CloudWatch Logs for application logs
- CloudWatch Metrics for API Gateway and Lambda metrics
- WAF metrics for security monitoring
- API Gateway access logs for request tracking
- Lambda function logs for debugging 