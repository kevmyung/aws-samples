## Deploy Real-time endpoint with BYOC (Bring Your Own Container)

샘플 모델을 커스텀 컨테이너 기반 SageMaker Endpoint에 배포하기

## 1. Directory and File Structure

- `Dockerfile` : Defines the Docker image build specifications.

- `requirements.txt` : Installs the required python libraries.

- `inference.py` : Defines model loading, inference, and input/output format.

  - https://docs.aws.amazon.com/sagemaker/latest/dg/your-algorithms-inference-code.html

- `serve` : Contains the Flask script for API serving.

  - https://docs.aws.amazon.com/sagemaker/latest/dg/your-algorithms-inference-code.html#your-algorithms-inference-code-container-response

- `open-korean-text-2.1.0.jar` : Open Source text analyzer (Korean).

  - https://github.com/open-korean-text/open-korean-text

- `v1/labels.csv` : Sample label.

- `v1/model.h5` : Sample model.

- `v1/word_index.h5` : Sample word index.

  

## 2. Building the Docker Image

Build the Docker image using the following command:

```bash
$ docker build -t my_inference_image .
```

The Docker image will install the necessary libraries and execute the required commands.
As SageMaker Endpoint containers are executed with the command `docker run <image> serve`, the custom image should be able to host the API through the serve file.
Ensure that the ENTRYPOINT in the Dockerfile is set to automatically execute the serve script.

   

## 3. Pushing the Container to Amazon ECR

Tag and push the built container to the Amazon ECR:

```bash
$ docker tag my_inference_image:latest {ECR URI}/{my-inference-container}:latest

$ docker push {ECR URI}/{my-inference-container}:latest
```

## 4. Uploading the Artifacts to S3

Compress the model and index into `model.tar.gz`, upload it to an S3 bucket, and then register it as a SageMaker Model:

```bash
$ tar -czvf model.tar.gz v1

$ aws s3 cp model.tar.gz s3://{bucket_name}/model.tar.gz
```

### Registering Model

The `model.tar.gz` file is registered as a SageMaker Model and deployed. When the container is executed, it will automatically extract the contents into the
`/opt/ml/model` directory.

```python
import boto3
from sagemaker import get_execution_role

sagemaker_client = boto3.client('sagemaker')
role = get_execution_role()

create_model_response = sagemaker_client.create_model(
    ModelName='my_model',
    ExecutionRoleArn=role,
    PrimaryContainer={
        'Image': '{ECR URI}/{my-inference-container}:latest',
        'ModelDataUrl': 's3://{bucket_name}/model.tar.gz'
    }
)
```

## 5. Creating Endpoint Config and Endpoint

### Creating Endpoint Config

```python
create_endpoint_config_response = sagemaker_client.create_endpoint_config(
    EndpointConfigName='my-ep-config',
    ProductionVariants=[
        {
            'VariantName': 'AllTraffic',
            'ModelName': 'my_model',
            'InitialInstanceCount': 1,
            'InstanceType': 'ml.m5.large',
            'InitialVariantWeight': 1
        }
    ]
)
```

### Creating Endpoint

```python
create_endpoint_response = sagemaker_client.create_endpoint(
    EndpointName='my-ep',
    EndpointConfigName='my-ep-config'
)
```

## 6. Testing the Endpoint

Once the SageMaker console shows the endpoint status as `InService``, you can test if the real-time endpoint is functioning correctly.

### Invoking Endpoint

```python
import json
import boto3

runtime_client = boto3.client('runtime.sagemaker')

response = runtime_client.invoke_endpoint(
    EndpointName='my-ep',
    ContentType='application/json',
    Body=json.dumps({"input": '배추'})
)

result = json.loads(response['Body'].read().decode())
print(result)
```

### Expected Output

```plaintext
{
    "output": [4090801.0, 0.0017000000225380063]
}
```