import json
import boto3
import os
import logging
import time
from datetime import datetime
from botocore.exceptions import ClientError

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

def lambda_handler(event, context):
    logger.debug(f"Received event: {json.dumps(event)}")
    
    try:
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