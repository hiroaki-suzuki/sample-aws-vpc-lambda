import base64
import cgi
import io
import json
import os

import boto3

from api_lib.decorators import lambda_wrapper

BUCKET_NAME = os.getenv('BACKEND_BUCKET_NAME')
s3_client = boto3.client('s3')


@lambda_wrapper
def lambda_handler(event, context):
    content_type = event['headers']["content-type"]
    file_content = base64.b64decode(event['body'])
    fp = io.BytesIO(file_content)
    environ = {'REQUEST_METHOD': 'POST', 'CONTENT_TYPE': content_type}
    fs = cgi.FieldStorage(fp=fp, environ=environ, keep_blank_values=True)

    for f in fs.list:
        file_path = f"uploads/{f.filename}"
        s3_client.put_object(Bucket=BUCKET_NAME, Key=file_path, Body=f.value)

    return {
        'body': json.dumps({'message': 'File uploaded successfully'}),
    }
