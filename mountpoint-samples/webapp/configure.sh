#!/bin/bash
set -e

ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
BUCKET_NAME="s3-mountpoint-${ACCOUNT_ID}"
REGION=us-east-1

echo "1. Creating S3 Bucket : ${BUCKET_NAME}"
aws s3 mb s3://${BUCKET_NAME}

IAM_POLICY=$(cat <<EOM
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Action": [
				"s3:*",
				"s3-object-lambda:*",
				"lambda:InvokeFunction"
			],
			"Resource": "*"
		}
	]
}
EOM
)

POLICY_DOCUMENT=".s3-policy.json"
echo "$IAM_POLICY" > ${POLICY_DOCUMENT}

POLICY_NAME="AmazonS3CSIDriverPolicy"
echo "2. Creating IAM Policy : ${POLICY_NAME}"
aws iam create-policy --policy-name ${POLICY_NAME} --policy-document file://${POLICY_DOCUMENT}
sleep 3

CLUSTER_NAME=my-eks
POLICY_ARN=arn:aws:iam::${ACCOUNT_ID}:policy/${POLICY_NAME}
ROLE_NAME=AmazonEKS_S3_CSI_DriverRole
SERVICE_ACCOUNT=s3-csi-driver-sa

echo "3. Creating IAM Role and Service Account : ${ROLE_NAME} / ${SERVICE_ACCOUNT}"
eksctl create iamserviceaccount \
    --name $SERVICE_ACCOUNT \
    --namespace kube-system \
    --cluster $CLUSTER_NAME \
    --attach-policy-arn $POLICY_ARN \
    --approve \
    --role-name $ROLE_NAME \
    --region $REGION
    
kubectl describe sa s3-csi-driver-sa --namespace kube-system

echo "4. Deploying CSI driver"
kubectl apply -k "github.com/awslabs/mountpoint-s3-csi-driver/deploy/kubernetes/overlays/stable/"
sleep 15

echo "5. Checking CSI drivers"
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-mountpoint-s3-csi-driver