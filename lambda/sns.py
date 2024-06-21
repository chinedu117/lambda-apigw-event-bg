import os

import boto3
from botocore.exceptions import ClientError


PARAMETER_NAME = os.environ.get('SSM_PARAMETER_NAME','/dev/concurrent-job-count')

ssm = boto3.client('ssm')

def handler(
    event,
    context,
):
    
    parameter_name = PARAMETER_NAME
    
    response = ssm.get_parameter(
        Name=parameter_name,
        WithDecryption=True,
    )
    concurrent_job_count = int(response['Parameter']['Value'])


    if concurrent_job_count != 0:
        concurrent_job_count = concurrent_job_count - 1
        ssm.put_parameter(
            Name=parameter_name,
            Value=str(concurrent_job_count),
            Type='String',
            Overwrite=True
        )

    print(f'Concurrent job count is {concurrent_job_count}')
