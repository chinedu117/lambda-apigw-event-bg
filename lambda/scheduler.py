import json
import os

import boto3
from botocore.exceptions import ClientError

MAX_CONCURRENT_JOB_COUNT = int(os.environ.get('MAX_CONCURRENT_JOB_COUNT',5))
PARAMETER_NAME = os.environ.get('SSM_PARAMETER_NAME','/dev/concurrent-job-count')
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
            has_delay = 'delay' in body
            has_id = 'id' in body
            is_integer = True
            try:
                int(body.get('delay'))
            except:
                is_integer = False

            if not all([
                has_id,
                has_delay,
                is_integer,
            ]):
                response = error_response(
                    status_code=400,
                    message='Invalid Input',
                )
                return response
            
            if concurrent_job_count < MAX_CONCURRENT_JOB_COUNT:
                can_submit_task = True

            response = error_response(
                status_code=400,
                message='Max concurrency exceeded',
            )
            
            if not can_submit_task:
                return response
            
            send_job(
                request_body=event,
            )

            concurrent_job_count = concurrent_job_count + 1

            ssm.put_parameter(
                Name=parameter_name,
                Value=str(concurrent_job_count),
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

            response = error_response(
                status_code=400,
                message='Unsupported HTTP method',
            )

            return response
    
    except Exception as e:

        response = error_response(
            status_code=500,
            message=str(e),
        )

        return response

def error_response(
    status_code: int,
    message: str,
):
    error_message = {
        'message': message,
    }
    
    error_message_str = json.dumps(
        obj=error_message,
    )

    error_response = {
        'statusCode': status_code,
        'body': error_message_str,
    }

    return error_response

def send_job(
    request_body,
):
    lambda_client.invoke(
        FunctionName=EVENT_HANDLER_FUNCTION_NAME,
        InvocationType='Event',
        Payload=json.dumps(request_body)
    )
    