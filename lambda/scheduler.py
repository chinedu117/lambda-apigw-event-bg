import json
import os

import boto3
from botocore.exceptions import ClientError

MAX_CONCURRENT_JOB_COUNT = os.environ.get('MAX_CONCURRENT_JOB',5)
PARAMETER_NAME = os.environ.get('SSM_PARAMETER_NAME','dev/concurrent-job-count')
EVENT_HANDLER_FUNCTION_NAME = os.environ.get('EVENT_HANDLER_FUNCTION_NAME','')

ssm = boto3.client('ssm')
lambda_client = boto3.client('lambda')

def handler(
    event,
    context,
):
    
    try:
        operation = event['httpMethod']
        parameter_name = PARAMETER_NAME
        
        response = ssm.get_parameter(
            Name=parameter_name,
            WithDecryption=True,
        )
        concurrent_job_count = int(response['Parameter']['Value'])
        can_submit_task = False

        if operation == 'POST':
            body = json.loads(event['body'])

            if concurrent_job_count < MAX_CONCURRENT_JOB_COUNT:
                can_submit_task = True

            error_message = {
                'message': 'Max concurrency exceeded',
            }

            error_message_str = json.dumps(
                obj=error_message,
            )

            error_response = {
                'statusCode': 400,
                'body': error_message_str,
            }
            
            if not can_submit_task:
                return error_response
            
            send_job(
                request_body=body,
            )

            concurrent_job_count = concurrent_job_count + 1

            ssm.put_parameter(
                Name=parameter_name,
                Value=concurrent_job_count,
                Type='String',
                Overwrite=True
            )
            
            success_message = {
                'message': 'Task submitted',
            }
            success_message_str = json.dumps(
                obj=success_message,
            )
            success_response = {
                'statusCode': 200,
                'body': success_message_str,
            }

            return success_response
        
        else:
            return {
                'statusCode': 400,
                'body': json.dumps({'message': 'Unsupported HTTP method'})
            }
    
    except ClientError as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }


def send_job(
    request_body,
):
    lambda_client.invoke(
        FunctionName=EVENT_HANDLER_FUNCTION_NAME,
        InvocationType='Event',
        Payload=json.dumps(request_body)
    )
    