# Serverless App Rating API

A secure, serverless API for collecting and storing application ratings. Built with AWS Lambda, API Gateway, and CloudFront.

## 🌟 Features

- **Secure API Endpoint**: HTTPS-only access at `api.cloudsredevops.com`
- **Rating Collection**: Accepts app ratings with name, score, and description
- **Authentication**: Validates requests using JWT tokens
- **Security**: Protected by AWS WAF and CloudFront
- **Scalable**: Built on serverless architecture for high availability
- **Cost-Efficient**: Pay only for what you use

## 🏗️ Architecture

```
Client Request → CloudFront → API Gateway → Lambda → DynamoDB
```

1. **CloudFront**: 
   - Global CDN for low latency
   - Custom origin token for security
   - HTTPS enforcement

2. **API Gateway**:
   - HTTP API for better performance
   - Lambda integration for request handling
   - Detailed access logging
   - CloudWatch integration

3. **Lambda Function**:
   - Python 3.9 runtime
   - Token validation
   - Request validation and CORS handling
   - Data processing
   - DynamoDB interaction

4. **DynamoDB**:
   - Fast data retrieval by AppName and date
   - Auto-scaling for large datasets

## 📐 Reference Diagram

The architecture follows a layered security approach with CloudFront as the entry point, providing DDoS protection and caching. The diagram shows the flow of requests through various AWS services, with each layer adding its own security and functionality. For a detailed view of the infrastructure, refer to the architecture diagram in the project documentation.

## 🔒 Security Features

- HTTPS-only access
- External token-based authentication
- CloudFront origin token validation
- WAF protection against malicious requests
- CORS restrictions to `cloudsredevops.com`
- Secrets stored in AWS Secrets Manager

### Authentication Flow
1. **Token-based Authentication**:
   - Uses external validation endpoint
   - Validation endpoint URL stored in AWS Secrets Manager
   - Lambda retrieves endpoint URL at runtime
   - External service handles token verification
   - No token validation logic in Lambda

2. **Security Benefits**:
   - Centralized token validation
   - Improved security through external validation
   - Better maintainability
   - Reduced Lambda complexity

## 🚀 API Usage

### Endpoint
```
POST https://api.cloudsredevops.com
```

### Headers
```
Authorization: Bearer <your-jwt-token>
Content-Type: application/json
```

### Sample Request
```bash
curl --location --request POST 'https://api.cloudsredevops.com' \
--header 'Authorization: Bearer <your-jwt-token>' \
--header 'Content-Type: application/json' \
--data-raw '{
    "AppName": "TestApp6",
    "Rating": 4,
    "Description": "This is a test app description"
}'
```

Note: The CloudFront origin token is automatically handled by CloudFront when requests come from the allowed domain (`cloudsredevops.com`). You don't need to include it in your requests. And `<your-jwt-token`> should be replaced with the JWT token.

### Request Body
```json
{
    "AppName": "MyApp",
    "Rating": 5,
    "Description": "Great application!"
}
```

### Validation Rules
- AppName: Required, max 50 characters
- Rating: Required, integer between 1-5 (decimal values not accepted)
- Description: Optional, max 2000 characters

## 🛠️ Infrastructure Setup

### Prerequisites
1. **AWS Resources**:
   - AWS Account with appropriate permissions
   - Route53 hosted zone
   - S3 bucket for Terraform state
   - External authentication service

2. **Configuration Files**:
   - `backend.tfvars`:
     ```hcl
     bucket  = "#BUCKET-NAME-HERE"
     key     = "terraform.tfstate"
     region  = "#BUCKET-REGION"
     encrypt = true
     ```
   
   - `secrets-input.tfvars`:
     ```hcl
     aws_access_key         = "your-aws-access-key"
     aws_secret_key         = "your-aws-secret-key"
     route53zoneid         = "your-route53-zone-id"
     auth_url             = "your-auth-validation-endpoint"
     cloudfront_origin_token = "your-cloudfront-token"
     ```

### Deployment Steps

1. **Initialize Terraform**:
   ```bash
   # Initialize with backend configuration
   terraform init -backend-config="backend.tfvars"
   
   # Review planned changes
   terraform plan -var-file="secrets-input.tfvars"
   ```

2. **Apply Infrastructure**:
   ```bash
   # Apply the configuration
   terraform apply -var-file="secrets-input.tfvars"
   ```

### Infrastructure Components Created
- CloudFront Distribution
- API Gateway HTTP API
- Lambda Function
- DynamoDB Table
- WAF Web ACL
- S3 Bucket for Logs
- IAM Roles and Policies
- Secrets Manager Secret
- Route53 Records

## 📊 Monitoring

- CloudWatch Logs for application logs
- CloudFront access logs in S3
- WAF logs for security monitoring

## 💰 Cost Optimization

- Serverless architecture (pay per use)
- CloudFront caching
- DynamoDB auto-scaling
- Log retention policies

## 🔄 CI/CD Pipeline

1. **Prepare Stage**
   - Package Lambda function
   - Install dependencies

2. **Terraform Stages**
   - Initialize backend
   - Plan changes
   - Apply changes (manual approval)

## ⚖️ Advantages

- **Scalability**: Auto-scales with demand
- **Security**: Multiple layers of protection
- **Cost**: Pay-per-use pricing
- **Maintenance**: No server management
- **Performance**: Global CDN distribution

## ⚠️ Considerations

- **Cold Starts**: Lambda initialization delay
- **Cost**: Can be higher for high-traffic applications
- **Complexity**: Multiple AWS services to manage
- **Debugging**: Distributed logging across services

## 🔧 Troubleshooting

1. **API Not Responding**
   - Check CloudFront distribution
   - Verify Lambda function status
   - Check API Gateway logs

2. **Authentication Failures**
   - Validate JWT token
   - Check CloudFront origin token
   - Verify CORS configuration
