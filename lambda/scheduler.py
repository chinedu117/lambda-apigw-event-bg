import json
import os

import boto3
from boto3.dynamodb import conditions
from botocore.exceptions import ClientError

MAX_CONCURRENT_JOB_COUNT = int(os.environ.get('MAX_CONCURRENT_JOB_COUNT',5))
EVENT_HANDLER_FUNCTION_NAME = os.environ.get('EVENT_HANDLER_FUNCTION_NAME','')
lambda_client = boto3.client('lambda')
USERS_TABLE_NAME = os.environ.get('USERS_TABLE_NAME','UsersConcurrentJobsCount' )
dynamodb = boto3.resource('dynamodb')

def handler(
    event,
    context,
):
    
    try:
        operation = event['httpMethod']
        table = dynamodb.Table(USERS_TABLE_NAME)
        
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
            
            user_id = str(body.get('id'))
            result = table.query(
                KeyConditionExpression=conditions.Key('userId').eq(user_id)
            )
            user = None
            if result['Count'] > 0:
                user = result['Items'][0]
            
            if not user:
                new_user = {
                    'userId': user_id,
                    'jobCount': "0"
                }
                table.put_item(
                    Item=new_user,
                )
                response = table.get_item(
                    Key={
                        'userId': user_id,
                    }
                )
                user = response.get('Item')

            concurrent_job_count = int(user.get('jobCount'))
            can_submit_task = False

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

            user['jobCount'] = str(concurrent_job_count)
            table.put_item(
                Item=user,
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
    