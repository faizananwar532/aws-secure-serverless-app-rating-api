#!/bin/bash

# # Create virtual environment if it doesn't exist
# if [ ! -d "venv" ]; then
#     python3 -m venv venv
# fi

# # Activate virtual environment
# source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Create deployment package
mkdir deployment-package
cd deployment-package 
rm -rf ./*
cp ../api/app.py .
pip install -r ../api/requirements.txt -t .
zip -r ../lambda_function.zip .

# Deactivate virtual environment
# deactivate

echo "Lambda function packaged successfully and deployed!" 
aws lambda update-function-code --function-name devops-test-prod-api --zip-file fileb://../lambda_function.zip
