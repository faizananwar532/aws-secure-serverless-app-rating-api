import json
import boto3
import os
import logging
import time
from datetime import datetime
from botocore.exceptions import ClientError
import requests

# Configure logger
logger = logging.getLogger()
logger.setLevel(logging.DEBUG)  # Enable debug, info, and error logs

# Add a stream handler if running locally or in Lambda
if not logger.handlers:
    handler = logging.StreamHandler()
    formatter = logging.Formatter('%(asctime)s %(levelname)s %(message)s')
    handler.setFormatter(formatter)
    logger.addHandler(handler)

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb')
# Initialize Secrets Manager client
secrets_manager = boto3.client('secretsmanager')

def get_secrets():
    """Retrieve secrets from AWS Secrets Manager"""
    try:
        # Get the name of the secret from environment variable
        secret_name = os.environ.get('AUTH_URL_SECRET_NAME', 'cloud-re-devops-secrets')
        if not secret_name:
            logger.warning("AUTH_URL_SECRET_NAME environment variable not set. Using default secret name")
            secret_name = 'cloud-re-devops-secrets'

        # Get the secret value
        response = secrets_manager.get_secret_value(SecretId=secret_name)
        secret = json.loads(response['SecretString'])
        
        logger.debug(f"Retrieved secrets from Secrets Manager: {secret}")
        return secret
    except Exception as e:
        logger.error(f"Error retrieving secrets from Secrets Manager: {e}")
        # Fallback to environment variables
        return {
            'AUTH_URL': os.environ.get('AUTH_URL'),
            'DYNAMODB_TABLE': os.environ.get('DYNAMODB_TABLE')
        }
        
        # Get the secret value
        response = secrets_manager.get_secret_value(SecretId=secret_name)
        secret = json.loads(response['SecretString'])
        
        logger.debug(f"Retrieved secrets from Secrets Manager: {secret}")
        return secret
    except Exception as e:
        logger.error(f"Error retrieving secrets from Secrets Manager: {e}")
        # Fallback to environment variables
        return {
            'AUTH_URL': os.environ.get('AUTH_URL'),
            'DYNAMODB_TABLE': os.environ.get('DYNAMODB_TABLE')
        }

def get_auth_url():
    """Retrieve authentication URL from secrets"""
    return get_secrets().get('AUTH_URL')

def validate_token(token, auth_url):
    """Validate the access token against the auth endpoint"""
    try:
        logger.debug(f"Validating token against auth URL: {auth_url}")
        
        # Make request to auth endpoint
        headers = {'Authorization': f'Bearer {token}'}
        response = requests.get(auth_url, headers=headers, timeout=5)
        
        if response.status_code == 200:
            logger.info("Token validation successful")
            return True
        else:
            logger.warning(f"Token validation failed: {response.status_code} - {response.text}")
            return False
    except Exception as e:
        logger.error(f"Error validating token: {e}")
        return False

def lambda_handler(event, context):
    logger.debug(f"Received event: {json.dumps(event)}")
    
    try:
        # Get secrets from Secrets Manager
        secrets = get_secrets()
        DYNAMODB_TABLE = secrets.get('DYNAMODB_TABLE')
        
        # Check for authentication token
        auth_header = None
        if 'headers' in event:
            # Extract Authorization header (case-insensitive)
            headers = {k.lower(): v for k, v in event['headers'].items()}
            auth_header = headers.get('authorization')
        
        if not auth_header:
            logger.error("Authorization header missing")
            return response(401, {'message': 'Authorization header is required'})
        
        # Extract token from Authorization header
        token_parts = auth_header.split(' ')
        if len(token_parts) != 2 or token_parts[0].lower() != 'bearer':
            logger.error("Invalid Authorization header format")
            return response(401, {'message': 'Authorization header must be in format: Bearer <token>'})
        
        token = token_parts[1]
        
        # Get auth URL from Secrets Manager
        auth_url = get_auth_url()
        
        # Validate token
        if not validate_token(token, auth_url):
            return response(401, {'message': 'Invalid or expired token'})
        
        # Parse input from the request body
        if 'body' in event:
            try:
                body = json.loads(event['body'])
                logger.debug(f"Parsed body from event['body']: {body}")
            except Exception as e:
                logger.error(f"Failed to parse event['body']: {e}")
                body = event['body']  # In case it's already parsed
        else:
            body = event  # For direct Lambda testing
            logger.debug(f"Using event as body: {body}")
        
        # Validate required fields
        app_name = body.get('AppName', '')
        rating = body.get('Rating', 0)
        description = body.get('Description', '')
        
        if not app_name or len(app_name) > 50:
            logger.error("AppName is required and must be less than 50 characters")
            return response(400, {'message': 'AppName is required and must be less than 50 characters'})
            
        try:
            rating = int(rating)
            if rating < 1 or rating > 5:
                logger.error("Rating must be between 1 and 5")
                return response(400, {'message': 'Rating must be between 1 and 5'})
        except (ValueError, TypeError):
            logger.error("Rating must be a number between 1 and 5")
            return response(400, {'message': 'Rating must be a number between 1 and 5'})
            
        if len(description) > 2000:
            logger.error("Description must be less than 2000 characters")
            return response(400, {'message': 'Description must be less than 2000 characters'})
        
        # Get table name from environment variable or use default
        table_name = os.environ.get('DYNAMODB_TABLE', 'AppRatings')
        # Get table name from secrets
        table_name = secrets.get('DYNAMODB_TABLE')
        table = dynamodb.Table(table_name)
        
        # Create timestamp for sorting
        timestamp = datetime.utcnow().isoformat()
        
        # Create item to store in DynamoDB
        item = {
            'AppName': app_name,
            'CreatedAt': timestamp,
            'Rating': rating,
            'Description': description,
            # Add a unique ID to avoid conflicts when multiple ratings for the same app
            'RatingId': f"{app_name}_{int(time.time() * 1000)}"
        }
        logger.debug(f"Item to be stored in DynamoDB: {item}")
        
        # Store in DynamoDB
        table.put_item(Item=item)
        
        logger.info(f"Successfully stored rating for app: {app_name}")
        return response(200, {'message': 'Rating saved successfully', 'item': item})
        
    except ClientError as e:
        logger.error(f"DynamoDB error: {e}")
        return response(500, {'message': f'Database error: {str(e)}'})
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        return response(500, {'message': f'Server error: {str(e)}'})

def response(status_code, body):
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*.cloudsredevops.com',
            'Access-Control-Allow-Headers': 'Content-Type,Authorization',
            'Access-Control-Allow-Methods': 'POST,OPTIONS'
        },
        'body': json.dumps(body)
    }