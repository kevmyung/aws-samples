import json
import requests
import xmltodict
import os

def handler(event, context):
    print(event)

    input_s3_url = event['listObjectsV2Context']['inputS3Url']
    response = requests.get(input_s3_url)
    
    if response.status_code >= 400:
        error = xmltodict.parse(response.content)
        return {
            "statusCode": response.status_code,
            "errorCode": error["Error"]["Code"],
            "errorMessage": error["Error"]["Message"]
        }
    
    response_dict = xmltodict.parse(response.content)

    contents = response_dict.get('ListBucketResult', {}).get('Contents', [])
    if not isinstance(contents, list):
        contents = [contents]

    filtered_contents = [
        obj for obj in contents
        if os.path.basename(obj['Key']).lower().endswith('.jpg') and os.path.basename(obj['Key']).startswith('360-')
    ]
    response_dict['ListBucketResult']['Contents'] = filtered_contents

    list_result_xml = xmltodict.unparse(response_dict)

    return {
        'statusCode': 200,
        'listResultXml': list_result_xml
    }
