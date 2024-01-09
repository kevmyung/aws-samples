#!/bin/bash
set -e

ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
BUCKET_NAME="s3-mountpoint-${ACCOUNT_ID}"
REGION=us-east-1

echo "Creating PV/PVC"
S3_PV=s3-pv
S3_PVC=s3-pvc

cat <<EOM > s3-pv-pvc.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: $S3_PV
spec:
  capacity:
    storage: 1000Gi
  accessModes:
    - ReadWriteMany
  mountOptions:
    - allow-delete
    - region $REGION
  csi:
    driver: s3.csi.aws.com
    volumeHandle: s3-csi-driver-volume
    volumeAttributes:
      bucketName: $BUCKET_NAME
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: $S3_PVC
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: ""
  resources:
    requests:
      storage: 1000Gi
  volumeName: $S3_PV
EOM

kubectl apply -f s3-pv-pvc.yaml