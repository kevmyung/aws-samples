
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
BUCKET_NAME="s3-mountpoint-${ACCOUNT_ID}"
REGION=us-east-1

aws s3 rm s3://${BUCKET_NAME}/ --recursive

kubectl delete configmap web-page
kubectl delete configmap image-app

kubectl delete -f app.yaml

kubectl create configmap web-page --from-file=./src/index.html
kubectl create configmap image-app --from-file=./src/app-1.js

kubectl apply -f app.yaml