S3_PV_1=s3-pv-1
S3_PV_2=s3-pv-2

S3_PVC_1=s3-pvc-1
S3_PVC_2=s3-pvc-2

cat <<EOM > s3-pv-pvc.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: $S3_PV_1
spec:
  capacity:
    storage: 1000Gi
  accessModes:
    - ReadWriteMany
  mountOptions:
    - allow-delete
    - region $REGION
    - prefix source/
  csi:
    driver: s3.csi.aws.com
    volumeHandle: s3-csi-driver-volume-1
    volumeAttributes:
      bucketName: $BUCKET_NAME
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: $S3_PVC_1
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: ""
  resources:
    requests:
      storage: 1000Gi
  volumeName: $S3_PV_1
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: $S3_PV_2
spec:
  capacity:
    storage: 1000Gi
  accessModes:
    - ReadWriteMany
  mountOptions:
    - allow-delete
    - region $REGION
    - prefix target/
  csi:
    driver: s3.csi.aws.com
    volumeHandle: s3-csi-driver-volume-2
    volumeAttributes:
      bucketName: $BUCKET_NAME
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: $S3_PVC_2
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: ""
  resources:
    requests:
      storage: 1000Gi
  volumeName: $S3_PV_2
EOM

kubectl apply -f s3-pv-pvc.yaml
sleep 3

echo "============================"
echo "2. Running Pod"

cat <<EOM > pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
spec:
  containers:
  - name: test-container
    image: python:3.8
    command: ["/bin/sh"]
    args: ["-c", "ls /data1 && ls /data2"]
    volumeMounts:
    - name: data-volume-1
      mountPath: /data1
    - name: data-volume-2
      mountPath: /data2
  volumes:
  - name: data-volume-1
    persistentVolumeClaim:
      claimName: $S3_PVC_1
  - name: data-volume-2
    persistentVolumeClaim:
      claimName: $S3_PVC_2
EOM

kubectl apply -f app.yaml
