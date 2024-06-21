import json
import time
import os
import boto3


EVENT_BUS_NAME = os.environ.get('EVENT_BUS_NAME')
client = boto3.client('events')

def lambda_handler(event, context):
    body = json.loads(event['body'])
    delay = body.get('delay', 0)
    id_param = body.get('id')

    if isinstance(delay, int) and delay > 0 and id_param:
        time.sleep(delay)
        
        response = client.put_events(
            Entries=[
                {
                    'Source': 'my.custom.source',
                    'DetailType': 'LambdaFunctionCompleted',
                    'Detail': json.dumps({'message': 'Lambda function completed successfully', 'id': id_param}),
                    'EventBusName': EVENT_BUS_NAME
                }
            ]
        )

        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'Lambda function completed successfully', 'event_response': response})
        }
    
    else:

        return {
            'statusCode': 400,
            'body': json.dumps({'message': 'Invalid delay or id parameter'})
        }