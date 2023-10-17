import json
import os

import boto3
from botocore.exceptions import NoCredentialsError, BotoCoreError, PartialCredentialsError

from api_lib.decorators import lambda_wrapper

BUCKET_NAME = os.getenv('BACKEND_BUCKET_NAME')
s3_client = boto3.client('s3')

s3 = boto3.resource('s3')
bucket = s3.Bucket(BUCKET_NAME)


@lambda_wrapper
def lambda_handler(event, context):
    objects = bucket.objects.filter(Prefix='uploads/')

    files = []
    for obj in objects:
        files.append({
            'id': obj.key,
            'filename': obj.key.replace('uploads/', '')
        })

    return {
        'body': json.dumps({'files': files}),
    }
