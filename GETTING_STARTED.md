# Getting Started Guide

This guide will walk you through the process of implementing the serverless API endpoint with AWS Lambda, API Gateway REST API, Cognito, and WAF.

## Prerequisites

1. AWS Account with appropriate permissions
2. GitLab account for CI/CD
3. Python 3.9 or later
4. Terraform 1.5.7 or later
5. AWS CLI configured with appropriate credentials
6. A registered domain (e.g., cloudsredevops.com) in Route 53

## Step 1: Project Setup

1. Clone the repository:
   ```bash
   git clone <your-repository-url>
   cd <repository-name>
   ```

2. Create the required directory structure:
   ```bash
   mkdir -p api terraform gitlab
   ```

## Step 2: Configure AWS Credentials

1. Set up AWS credentials in your local environment:
   ```bash
   aws configure
   ```
   Enter your:
   - AWS Access Key ID
   - AWS Secret Access Key
   - Default region (e.g., us-east-1)
   - Default output format (json)

2. Create a `secrets-input.tfvars` file in the terraform directory:
   ```bash
   cd terraform
   touch secrets-input.tfvars
   ```

3. Add your sensitive variables to `secrets-input.tfvars`:
   ```hcl
   aws_access_key = "your-access-key"
   aws_secret_key = "your-secret-key"
   ```

## Step 3: Set Up AWS Cognito

1. The Cognito User Pool will be created automatically when you deploy the infrastructure. It includes:
   - User Pool with email authentication
   - App Client for your application
   - Password policies and security settings
   - OAuth 2.0 configuration

2. After deployment, you'll get these outputs:
   - `cognito_user_pool_id`: Your User Pool ID
   - `cognito_client_id`: Your App Client ID
   - `cognito_client_secret`: Your App Client Secret (sensitive)

3. To create a test user in the User Pool:
   ```bash
   aws cognito-idp admin-create-user \
     --user-pool-id <your-user-pool-id> \
     --username test@example.com \
     --temporary-password TempPass123! \
     --user-attributes Name=email,Value=test@example.com
   ```

4. To get an authentication token:
   ```bash
   aws cognito-idp admin-initiate-auth \
     --user-pool-id <your-user-pool-id> \
     --client-id <your-client-id> \
     --auth-flow ADMIN_USER_PASSWORD_AUTH \
     --auth-parameters USERNAME=test@example.com,PASSWORD=TempPass123!
   ```

5. Use the returned `IdToken` in your API requests:
   ```bash
   curl -X POST https://api.cloudsredevops.com/reviews \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer <your-id-token>" \
     -H "Origin: https://api.cloudsredevops.com" \
     -d '{
       "AppName": "TestApp",
       "Rating": 5,
       "Description": "Great app!"
     }'
   ```

## Step 4: Configure GitLab CI/CD

1. In your GitLab project, go to Settings > CI/CD > Variables
2. Add the following variables:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`

## Step 5: Set Up Python Environment

1. Create a virtual environment for the Lambda function:
   ```bash
   cd api
   python3 -m venv venv
   source venv/bin/activate
   ```

2. Install required packages:
   ```bash
   pip install -r requirements.txt
   ```

3. Test the packaging script:
   ```bash
   chmod +x package.sh
   ./package.sh
   ```

## Step 6: Configure Terraform

1. Create a unique S3 bucket name for your Terraform state:
   ```bash
   export TF_STATE_BUCKET="your-unique-terraform-state-bucket"
   ```

2. Update the backend configuration in `terraform/backend.tf`:
   ```hcl
   terraform {
     backend "s3" {
       bucket         = "your-unique-terraform-state-bucket"
       key            = "terraform.tfstate"
       region         = "us-east-1"
       dynamodb_table = "terraform-state-lock"
       encrypt        = true
     }
   }
   ```

3. Initialize Terraform with the new backend:
   ```bash
   cd terraform
   terraform init -backend-config=backend.tfvars
   ```

4. Update `input.tfvars` with your configuration:
   ```hcl
   environment = "dev"
   domain_name = "cloudsredevops.com"
   api_subdomain = "api"
   allowed_subdomains = ["app", "admin"]
   ```

## Step 7: Deploy the Infrastructure

1. First, create the state management resources:
   ```bash
   terraform apply -var-file="secrets-input.tfvars" -var-file="input.tfvars" -target=aws_s3_bucket.terraform_state -target=aws_dynamodb_table.terraform_state_lock
   ```

2. Then, deploy the rest of the infrastructure:
   ```bash
   terraform apply -var-file="secrets-input.tfvars" -var-file="input.tfvars"
   ```

## Step 8: Verify the Deployment

1. Check AWS Console for:
   - Lambda function creation
   - API Gateway REST API setup
   - DynamoDB table
   - WAF rules (associated with the REST API stage)

2. Test the API endpoint:
   ```bash
   curl -X POST https://api.cloudsredevops.com/reviews \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer <your-id-token>" \
     -H "Origin: https://api.cloudsredevops.com" \
     -d '{
       "AppName": "TestApp",
       "Rating": 5,
       "Description": "Great app!"
     }'
   ```

## Step 9: Monitor and Maintain

1. Set up CloudWatch alarms for:
   - API Gateway errors
   - Lambda function errors
   - WAF blocked requests

2. Regularly check:
   - CloudWatch logs
   - API Gateway metrics

## Troubleshooting

### Common Issues

1. **Lambda Deployment Package Issues**
   - Ensure all dependencies are in the zip file
   - Check Python version compatibility
   - Verify file permissions

2. **API Gateway Issues**
   - Check CORS configuration
   - Verify custom domain setup
   - Check WAF rules

3. **Secrets Manager Issues**
   - Verify IAM permissions
   - Check secret value format
   - Ensure Lambda has access to the secret

### Debugging Steps

1. Check CloudWatch logs for errors
2. Verify environment variables in Lambda
3. Test API Gateway endpoints directly
4. Check WAF logs for blocked requests

## Security Considerations

1. Regularly rotate AWS credentials
2. Update dependencies for security patches
3. Monitor WAF rules and adjust as needed
4. Review IAM permissions regularly
5. Enable AWS CloudTrail for audit logging

## Maintenance

1. Regular updates:
   - Python dependencies
   - Terraform version
   - AWS provider version

2. Backup procedures:
   - DynamoDB table
   - Secrets Manager secrets
   - Terraform state

3. Monitoring:
   - Set up CloudWatch dashboards
   - Configure alerts
   - Regular log analysis

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review AWS documentation
3. Contact the development team
4. Submit issues in the repository

## Additional Resources

- [AWS Lambda Documentation](https://docs.aws.amazon.com/lambda/)
- [API Gateway Documentation](https://docs.aws.amazon.com/apigateway/)
- [Secrets Manager Documentation](https://docs.aws.amazon.com/secretsmanager/)
- [Terraform Documentation](https://www.terraform.io/docs)
- [GitLab CI/CD Documentation](https://docs.gitlab.com/ee/ci/) 