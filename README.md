# AWS Secure Serverless App Rating API

A secure, serverless application rating API built on AWS with comprehensive security measures and monitoring.

## Architecture Requirements Implementation
The application follows a serverless architecture with the following components:
### API Endpoint Requirements
1. **HTTPS POST Request Handling**
   - Implemented using API Gateway HTTP API
   - Request validation for parameters:
     - AppName: String, max 50 chars
     - Rating: Number, range 1-5
     - Description: String, max 2000 chars
   - Input validation handled in Lambda function

2. **Authentication**
   - Token-based authentication using external validation endpoint
   - Token validation endpoint configured via environment variables
   - Lambda function validates tokens before processing requests

3. **Domain Access Control**
   - Custom domain: api.cloudsredevops.com
   - WAF rules restrict access to cloudsredevops.com subdomains
   - CORS configuration in API Gateway
   - Host header validation in WAF

4. **Data Storage & Retrieval**
   - DynamoDB table with optimized schema:
     - Partition key: AppName
     - Sort key: CreateDate
   - Global Secondary Index for efficient date-based queries
   - Auto-scaling enabled for cost efficiency

5. **Logging & Monitoring**
   - CloudWatch Logs for application logs:
     - Error logs
     - Info logs
     - Debug logs
   - CloudFront access logs in S3
   - API Gateway logs in CloudWatch
   - WAF logs for security monitoring

6. **Serverless Architecture**
   - Lambda for compute
   - API Gateway for HTTP endpoints
   - DynamoDB for database
   - CloudFront for CDN
   - No servers to manage

7. **Security Measures**
   - WAF rules for malicious request detection:
     - Rate limiting
     - SQL injection protection
     - Suspicious user agent blocking
     - AWS managed rules
   - SSL/TLS encryption
   - Secrets management
   - IP-based access control

8. **High Availability**
   - Multi-AZ deployment
   - CloudFront global distribution
   - DynamoDB global tables
   - API Gateway multi-region deployment

9. **Cost Efficiency**
   - Pay-per-use pricing model
   - Auto-scaling resources
   - CloudFront caching
   - DynamoDB on-demand capacity


## Infrastructure Setup

1. Initialize Terraform with backend configuration:
```bash
terraform init -backend-config="backend.tfvars"
```

2. Create a `secrets-input.tfvars` file with required variables:
```hcl
route53zoneid = "your-route53-zone-id"
```

3. Apply the Terraform configuration:
```bash
terraform apply -var-file="secrets-input.tfvars"
```

## Infrastructure Components

### CloudFront & WAF
- CloudFront distribution with custom domain
- WAF rules for security
- S3 bucket for CloudFront logs

### API Gateway
- HTTP API with Lambda integration
- Custom domain configuration
- CloudWatch Logs integration

### Lambda Function
- Python-based application
- DynamoDB integration
- Environment variables from Secrets Manager

### Database
- DynamoDB table for ratings
- Auto-scaling configuration

### Security
- AWS Secrets Manager for sensitive data
- WAF rules for protection
- SSL/TLS encryption

## Monitoring

### Logs
- CloudFront logs in S3: `s3://app-ratings-logs-{account-id}/cloudfront-logs/`
- API Gateway logs in CloudWatch: `/aws/apigateway/app-ratings-http-api`

### Metrics
- WAF metrics in CloudWatch
- API Gateway metrics
- CloudFront metrics

## Security Features

1. **WAF Protection**:
   - Rate limiting
   - SQL injection protection
   - Suspicious user agent blocking
   - AWS managed rules

2. **Access Control**:
   - Host-based access control
   - IP-based rate limiting
   - User agent filtering

3. **Data Protection**:
   - SSL/TLS encryption
   - Secrets management
   - Secure API endpoints

## Maintenance

### Log Retention
- CloudFront logs: 90 days in S3
- API Gateway logs: 30 days in CloudWatch

### Updates
1. Update Lambda code:
   - Modify code in `api` directory
   - Create new zip file
   - Update Terraform configuration

2. Update WAF rules:
   - Modify rules in `waf.tf`
   - Apply changes with Terraform

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy -var-file="secrets-input.tfvars"
```

## Advantages and Disadvantages

### Advantages
1. **Cost Efficiency**
   - Pay-per-use model with Lambda and DynamoDB
   - No idle resources
   - Auto-scaling based on demand
   - CloudFront caching reduces backend load

2. **High Availability**
   - Multi-AZ deployment
   - No single point of failure
   - Automatic failover
   - Global distribution with CloudFront

3. **Security**
   - Comprehensive WAF protection
   - SSL/TLS encryption
   - Token-based authentication
   - Rate limiting and DDoS protection

4. **Scalability**
   - Automatic scaling with Lambda
   - DynamoDB auto-scaling
   - CloudFront edge caching
   - API Gateway throttling

5. **Maintainability**
   - Infrastructure as Code with Terraform
   - Centralized logging
   - Easy updates and rollbacks
   - Automated deployment pipeline

### Disadvantages
1. **Cold Start Latency**
   - Lambda functions may experience cold starts
   - Initial request might be slower
   - Can be mitigated with provisioned concurrency

2. **Cost at Scale**
   - Can become expensive with very high traffic
   - DynamoDB costs increase with data size
   - CloudFront data transfer costs

3. **Vendor Lock-in**
   - Solution is tightly coupled with AWS services
   - Migration would require significant changes
   - AWS-specific features used

4. **Complexity**
   - Multiple AWS services to manage
   - Requires understanding of various services
   - More complex than monolithic applications

5. **Debugging Challenges**
   - Distributed nature makes debugging complex
   - Need to check multiple services
   - Requires good logging setup

## License

[Your License Here]

## Contributing

[Your Contributing Guidelines Here] 