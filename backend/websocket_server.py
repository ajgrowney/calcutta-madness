# Calcutta Auction Webhook Lambda Entrypoints
# Use the auction business logic from auction.py
import json
import boto3
from botocore.exceptions import ClientError
import logging
import os
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TABLE_NAME'])

def lambda_handler(event, context):
    print(event)
    connection_id = event['requestContext']['connectionId']
    route_key = event['requestContext']['routeKey']

    if route_key == '$connect':
        return handle_connect(connection_id)
    elif route_key == '$disconnect':
        return handle_disconnect(connection_id)
    elif route_key == '$default':
        return handle_send_message(event)
    else:
        return {'statusCode': 400, 'body': 'Invalid route key'}

def handle_connect(connection_id):
    try:
        table.put_item(Item={'connectionId': connection_id})
        return {'statusCode': 200}
    except ClientError as e:
        return {'statusCode': 500, 'body': str(e)}

def handle_disconnect(connection_id):
    try:
        table.delete_item(Key={'connectionId': connection_id})
        return {'statusCode': 200}
    except ClientError as e:
        return {'statusCode': 500, 'body': str(e)}

def handle_send_message(event):
    try:
        # Send message to all connected clients
        data = json.loads(event['body'])['data']
        connections = table.scan().get('Items', [])
        api_gateway = boto3.client('apigatewaymanagementapi', endpoint_url=f"https://{event['requestContext']['domainName']}/{event['requestContext']['stage']}")
        print(f"Sending message to {len(connections)} connections: {data}")
        for connection in connections:
            print(f"Sending message to {connection['connectionId']} [{connection}]")
            try:
                res = api_gateway.post_to_connection(ConnectionId=connection['connectionId'], Data=json.dumps(data))
                print(f"Response: {res} [{connection['connectionId']}]")
            except ClientError as e:
                if e.response['Error']['Code'] == 'GoneException':
                    table.delete_item(Key={'connectionId': connection['connectionId']})
                else:
                    print(f"Error sending message to {connection['connectionId']}: {str(e)}")
            except Exception as e:
                print(f"Error sending message to {connection['connectionId']}: {str(e)}")
        print("Message sent to all connections")
        return {'statusCode': 200}
    except ClientError as e:
        return {'statusCode': 500, 'body': str(e)}
    except Exception as e:
        return {'statusCode': 500, 'body': str(e)}