import base64
import os
from urllib.parse import unquote

import boto3
from filetype import filetype

from api_lib.decorators import lambda_wrapper

BUCKET_NAME = os.getenv('BACKEND_BUCKET_NAME')
s3_client = boto3.client('s3')


@lambda_wrapper
def lambda_handler(event, context):
    params = event['pathParameters']
    filename = unquote(params['filename'])
    response = s3_client.get_object(Bucket=BUCKET_NAME, Key=f"uploads/{filename}")
    file_content = response['Body'].read()

    kind = filetype.guess(file_content)
    if kind is None:
        mime_type = "text/plain"
    else:
        mime_type = kind.mime

    return {
        'body': base64.b64encode(file_content).decode('utf-8'),
        'headers': {
            'Content-Disposition': f'attachment; filename={filename.encode()}',
            'Content-Type': mime_type,
        },
    }
