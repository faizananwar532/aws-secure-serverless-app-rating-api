import json
import os
import boto3
import logging
import requests
from datetime import datetime
from typing import Dict, Any, List
from aws_lambda_powertools import Logger
from aws_lambda_powertools.utilities.typing import LambdaContext
from aws_lambda_powertools.utilities.validation.exceptions import SchemaValidationError
from aws_lambda_powertools.utilities.parser import parse
from aws_lambda_powertools.utilities.parser.models import APIGatewayProxyEventModel
from aws_lambda_powertools.utilities.parser.envelopes import ApiGatewayEnvelope
import jwt
from jwt import PyJWKClient
from pydantic import BaseModel

# Configure logging
logger = Logger()
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['DYNAMODB_TABLE'])

# Initialize Secrets Manager client
secrets_client = boto3.client('secretsmanager')

# Get Cognito configuration from environment variables
COGNITO_USER_POOL_ID = os.environ['COGNITO_USER_POOL_ID']
COGNITO_CLIENT_ID = os.environ['COGNITO_CLIENT_ID']
COGNITO_REGION = os.environ['AWS_REGION']

# Initialize JWT client for Cognito
jwks_url = f'https://cognito-idp.{COGNITO_REGION}.amazonaws.com/{COGNITO_USER_POOL_ID}/.well-known/jwks.json'
jwks_client = PyJWKClient(jwks_url)

def validate_token(token: str) -> bool:
    """Validate the JWT token against Cognito"""
    try:
        # Get the key ID from the token header
        unverified_headers = jwt.get_unverified_header(token)
        key_id = unverified_headers['kid']
        
        # Get the public key
        public_key = jwks_client.get_signing_key(key_id).key
        
        # Verify the token
        decoded = jwt.decode(
            token,
            public_key,
            algorithms=['RS256'],
            audience=COGNITO_CLIENT_ID
        )
        
        # Check if token is expired
        if datetime.fromtimestamp(decoded['exp']) < datetime.now():
            logger.warning("Token has expired")
            return False
            
        return True
    except Exception as e:
        logger.error(f"Token validation error: {str(e)}")
        return False

# Get domain configuration from environment variables
DOMAIN_NAME = os.environ['DOMAIN_NAME']
ALLOWED_SUBDOMAINS = os.environ['ALLOWED_SUBDOMAINS'].split(',')

def get_secret(secret_name: str) -> Dict[str, Any]:
    """Retrieve secret from AWS Secrets Manager"""
    try:
        response = secrets_client.get_secret_value(SecretId=secret_name)
        if 'SecretString' in response:
            return json.loads(response['SecretString'])
        return {}
    except Exception as e:
        logger.error(f"Error retrieving secret {secret_name}: {str(e)}")
        raise

# Get token validation endpoint from Secrets Manager
TOKEN_VALIDATION_SECRET = os.environ['TOKEN_VALIDATION_SECRET']
token_config = get_secret(TOKEN_VALIDATION_SECRET)
TOKEN_VALIDATION_ENDPOINT = token_config.get('endpoint')

class AppReview(BaseModel):
    AppName: str
    Rating: int
    Description: str

    class Config:
        schema_extra = {
            "example": {
                "AppName": "MyApp",
                "Rating": 5,
                "Description": "Great application!"
            }
        }

def validate_origin(origin: str) -> bool:
    """Validate if the request origin is from allowed subdomains"""
    if not origin:
        return False
    
    try:
        # Extract domain from origin
        domain = origin.split('://')[1].split('/')[0]
        # Check if it's a subdomain of our domain
        if not domain.endswith(f".{DOMAIN_NAME}"):
            return False
        
        # If ALLOWED_SUBDOMAINS contains "*", allow all subdomains
        if "*" in ALLOWED_SUBDOMAINS:
            return True
            
        # Check if the subdomain is in the allowed list
        subdomain = domain.split('.')[0]
        return subdomain in ALLOWED_SUBDOMAINS
    except Exception as e:
        logger.error(f"Origin validation error: {str(e)}")
        return False

@logger.inject_lambda_context
@parse(event_model=APIGatewayProxyEventModel, envelope=ApiGatewayEnvelope)
def lambda_handler(event: APIGatewayProxyEventModel, context: LambdaContext) -> Dict[str, Any]:
    try:
        # Validate origin
        origin = event.headers.get('Origin', '')
        if not validate_origin(origin):
            logger.warning(f"Invalid origin: {origin}")
            return {
                'statusCode': 403,
                'body': json.dumps({'error': 'Invalid origin'})
            }

        # Validate token
        token = event.headers.get('Authorization', '').replace('Bearer ', '')
        if not validate_token(token):
            logger.warning("Invalid token")
            return {
                'statusCode': 401,
                'body': json.dumps({'error': 'Invalid token'})
            }

        # Parse and validate request body
        try:
            review = AppReview.parse_raw(event.body)
        except Exception as e:
            logger.error(f"Validation error: {str(e)}")
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'Invalid request body'})
            }

        # Validate input constraints
        if len(review.AppName) > 50:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'AppName must be 50 characters or less'})
            }
        
        if not 1 <= review.Rating <= 5:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'Rating must be between 1 and 5'})
            }
        
        if len(review.Description) > 2000:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'Description must be 2000 characters or less'})
            }

        # Save to DynamoDB
        item = {
            'AppName': review.AppName,
            'Rating': review.Rating,
            'Description': review.Description,
            'CreatedAt': datetime.utcnow().isoformat(),
            'CreatedAtTimestamp': int(datetime.utcnow().timestamp())
        }
        
        table.put_item(Item=item)
        logger.info(f"Successfully saved review for app: {review.AppName}")

        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'Review saved successfully'})
        }

    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Internal server error'})
        }

# Example curl command to test the REST API endpoint:
# curl -X POST \
#   -H "Content-Type: application/json" \
#   -H "Authorization: Bearer <JWT_TOKEN>" \
#   -H "Origin: https://api.cloudsredevops.com" \
#   -d '{"AppName": "MyApp", "Rating": 5, "Description": "Great application!"}' \
#   https://api.cloudsredevops.com/reviews