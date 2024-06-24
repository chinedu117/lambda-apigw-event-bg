import json
import os

import boto3
from botocore.exceptions import ClientError

USERS_TABLE_NAME = os.environ.get('USERS_TABLE_NAME','UsersConcurrentJobsCount' )

dynamodb = boto3.resource('dynamodb')

def handler(
    event,
    context,
):  
    table = dynamodb.Table(USERS_TABLE_NAME)
    try:
        event_str = json.dumps(
            obj=event,
        )
        event_json = json.loads(s=event_str)
        event_msg_str = event_json['Records'][0]['Sns']['Message']
        sns_json_msg = json.loads(
            s=event_msg_str,
        )
    except json.decoder.JSONDecodeError:
        print('Unable to decode SNS message')

        return 
    print(sns_json_msg)
    user_id = sns_json_msg['userId']
    response = table.get_item(
        Key={
            'userId': user_id,
        }
    )
    user = response.get('Item')
    if user:
        print(user)
        concurrent_job_count = int(user['jobCount'])
        if concurrent_job_count != 0:
            concurrent_job_count = concurrent_job_count - 1
            user['jobCount'] = str(concurrent_job_count)
            table.put_item(
                Item=user,
            )
        print(f'Concurrent job count is {concurrent_job_count}')
    else:
        print('User not found')

        return    
