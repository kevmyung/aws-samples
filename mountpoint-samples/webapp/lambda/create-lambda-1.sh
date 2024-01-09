#!/bin/bash
set -e

ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
POLICY_DOCUMENT="trust-policy.json"
ROLE_NAME=LambdaImageHandlerRole
LAMBDA_NAME=image_handler

sudo yum install zip -y
rm -rf lambda-function lambda-function.zip

echo "Creating Lambda function : ${LAMBDA_NAME}"

mkdir lambda-function
cd lambda-function
npm init -y
npm install sharp aws-sdk
cp ../lambda-function-1.js ${LAMBDA_NAME}.js
zip -r ../lambda-function.zip *
cd ..

cat > ${POLICY_DOCUMENT} << EOM
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOM

aws iam create-role --role-name $ROLE_NAME --assume-role-policy-document file://$POLICY_DOCUMENT
aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AmazonRekognitionFullAccess
aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/CloudWatchLogsFullAccess

aws lambda create-function --function-name ${LAMBDA_NAME} --zip-file fileb://lambda-function.zip --handler ${LAMBDA_NAME}.handler --runtime nodejs18.x --role arn:aws:iam::$ACCOUNT_ID:role/$ROLE_NAME
aws lambda update-function-configuration --function-name ${LAMBDA_NAME} --timeout 15
