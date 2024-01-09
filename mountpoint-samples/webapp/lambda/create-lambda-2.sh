#!/bin/bash
set -e

ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
POLICY_DOCUMENT="trust-policy.json"
ROLE_NAME=LambdaListHandlerRole
LAMBDA_NAME=list_handler

sudo yum install zip -y
rm -rf lambda-function lambda-function.zip

echo "Creating Lambda function : ${LAMBDA_NAME}"
mkdir -p lambda-function/lambda_dependencies
cd lambda-function

pip download -d lambda_dependencies requests==2.28.2 xmltodict
cd lambda_dependencies
for whl in *.whl; do
    unzip $whl -d ../
    rm $whl
done
cd ..

cp ../lambda-function-2.py ${LAMBDA_NAME}.py
zip -r9 lambda-function.zip .
cp lambda-function.zip ..
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
aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/CloudWatchLogsFullAccess

RUNTIME=$(pip --version | awk -F'[()]' '{print $2}' | awk '{print $2}')
aws lambda create-function --function-name ${LAMBDA_NAME} --zip-file fileb://lambda-function.zip --handler ${LAMBDA_NAME}.handler --runtime python${RUNTIME} --role arn:aws:iam::$ACCOUNT_ID:role/$ROLE_NAME
sleep 10
aws lambda update-function-configuration --function-name ${LAMBDA_NAME} --timeout 15
