import json
import os
import traceback
import boto3
import random
import datetime
from botocore.exceptions import ClientError
from boto3.dynamodb.conditions import Key, Attr
from calcutta import get_tournament

dynamodb = boto3.resource('dynamodb')
AUCTION_TABLE = os.getenv('TABLE_NAME', 'calcutta_auction')
CONNECTION_TABLE = os.getenv('CONNECTION_TABLE', 'calcutta_connections')
WS_ENDPOINT = os.getenv('WEBSOCKET_API_ENDPOINT')
ITEM_STARTING_PRICE = 1
def respond(err, res=None):
    return {
        'statusCode': '400' if err else '200',
        'body': json.dumps({'message': err} if err else res, default=str),
        'headers': {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
            'Content-Type': 'application/json',
        },
    }

def get_user_id(event):
    print(f"Getting userid from authorizer: {event['requestContext']['authorizer']}")
    return event['requestContext']['authorizer']['claims']['sub']
def get_user_claims(event):
    return event['requestContext'].get('authorizer', {}).get('claims',{})

def create_auction(event, context):
    body = json.loads(event['body'])
    auction_id = body['auctionId']
    name = body['name']
    auction_type = body.get('type', 'march-2025')
    tournament = get_tournament(auction_type)
    auction_state = 'UPCOMING'
    user = get_user_claims(event)
    user_id = user.get('sub', '')
    user_email = user.get('email', '')
    table = dynamodb.Table(AUCTION_TABLE)
    try:
        dynamodb.meta.client.transact_write_items(
            TransactItems=[
                { # Create the auction metadata
                    "Put": {
                        "TableName": AUCTION_TABLE,
                        "Item": {
                            "PK": f"AUCTION#{auction_id}",
                            "SK": "METADATA",
                            "auctionId": auction_id,
                            "admin": user_id,
                            "name": name,
                            "type": auction_type,
                            "auctionState": auction_state
                        },
                        # Ensure the auction does not already exist
                        "ConditionExpression": "attribute_not_exists(PK)",
                    }
                },
                { # Add the user to the auction as an admin
                    "Put": {
                        "TableName": AUCTION_TABLE,
                        "Item": {
                            "PK": f"AUCTION#{auction_id}",
                            "SK": f"USER#{user_id}",
                            "role": "admin"
                        }
                    }
                },
                { # Add the auction to the user's list of auctions
                    "Put": {
                        "TableName": AUCTION_TABLE,
                        "Item": {
                            "PK": f"USER#{user_id}",
                            "SK": f"AUCTION#{auction_id}",
                            "role": "admin"
                        }
                    }
                },
            ]
        )
        print(f"Adding items to auction: {auction_id}: {tournament.get('items')}")
        tourney_groups = tournament.get("groups", {})
        print(f"Groups: {tourney_groups}")
        with table.batch_writer() as batch:
            for item in tournament.get("items"):
                print(f"Adding item: {item}")
                batch.put_item(
                    Item={
                        "PK": f"AUCTION#{auction_id}",
                        "SK": f"ITEM#{item['id']}",
                        "name": item.get("name", "Unknown"),
                        "seed": item.get("seed"),
                        "region": item.get("region", ""),
                        "price": 0,
                        "bidder": "",
                        "auctioned": False,
                        "group_info": tourney_groups.get(item['id'],{})
                    }
                )

        return respond(None, {'auctionId': auction_id, 'name': name, 'auctionState': auction_state})
    except ClientError as e:
        return respond(e.response['Error']['Message'])
    except Exception as e:
        return respond(str(e))

def get_user_auctions(event, context):
    table = dynamodb.Table(AUCTION_TABLE)
    try:
        user_id = get_user_id(event)
        response = table.query(
            KeyConditionExpression=Key('PK').eq(f'USER#{user_id}') & Key('SK').begins_with('AUCTION#'),
        )
        auctions = [{"auctionId": item["SK"].split("#")[1], "role": item["role"]} for item in response["Items"]]
        # Get the auction name and status for each
        for auction in auctions:
            auction_metadata = table.get_item(
                Key={"PK": f"AUCTION#{auction['auctionId']}", "SK": "METADATA"}
            )
            auction["name"] = auction_metadata["Item"]["name"]
            auction["auctionState"] = auction_metadata["Item"]["auctionState"]
        return respond(None, auctions)
    except ClientError as e:
        return respond(e.response['Error']['Message'])
    except Exception as e:
        print(traceback.format_exc())
        return respond(str(e))

def get_user_info(event, context):
    user_id = get_user_id(event)
    table = dynamodb.Table(AUCTION_TABLE)
    try:
        response = table.get_item(
            Key={'PK': f'USER#{user_id}'}
        )
        return respond(None, response['Item'])
    except ClientError as e:
        return respond(e.response['Error']['Message'])

def get_auction_items(event, context):
    table = dynamodb.Table(AUCTION_TABLE)
    auction_id = event['pathParameters']['auctionId']
    
    try:
        response = table.query(
            KeyConditionExpression=Key('PK').eq(f'AUCTION#{auction_id}') & Key('SK').begins_with('ITEM#')
        )
        
        items = []
        for item in response.get('Items', []):
            item_id = item['SK'].split('#')[1]
            if item_id.startswith('g'):
                item_obj = {
                    'type': 'group',
                    'id': item_id,
                    'name': item.get('name', 'Unknown'),
                    'region': item.get('region', ''),
                    'price': item.get('price', 0),
                    'bidder': item.get('bidder', ''),
                    'auctioned': item.get('auctioned', False),
                    'closed_at': item.get('closed_at', ''),
                    'info': item.get('group_info', {})
                }
            else:
                item_obj = ({
                    'type': 'team',
                    'id': item_id,
                    'name': item.get('name', 'Unknown'),
                    'seed': item.get('seed'),
                    'region': item.get('region', ''),
                    'price': item.get('price', 0),
                    'bidder': item.get('bidder', ''),
                    'auctioned': item.get('auctioned', False),
                    'closed_at': item.get('closed_at', '')
                })
            items.append(item_obj)
        
        return respond(None, items)
    except ClientError as e:
        return respond(e.response['Error']['Message'])

def get_auction_details(event, context):
    """Get complete details about an auction, including metadata, teams, and participants"""
    table = dynamodb.Table(os.getenv('TABLE_NAME', 'calcutta_auction'))
    try:
        auction_id = event['pathParameters']['auctionId']
        user_id = get_user_id(event)
        print(f"Getting auction details for {auction_id} and user {user_id}")
        # 1. First, get the auction metadata
        metadata_response = table.get_item(
            Key={'PK': f'AUCTION#{auction_id}', 'SK': 'METADATA'}
        )
        
        if 'Item' not in metadata_response:
            return respond(f"Auction {auction_id} not found")
            
        auction = metadata_response['Item']
        
        # Get the current item on the block
        current_item_response = table.get_item(
            Key={
                "PK": f"AUCTION#{auction_id}",
                "SK": "CURRENT_ITEM"
            }
        )
        current_item = current_item_response.get("Item", {})
        print(f"Current item: {current_item}")
        
        # 3. Finally, get all participants in this auction
        participants_response = table.query(
            KeyConditionExpression=Key('PK').eq(f'AUCTION#{auction_id}') & Key('SK').begins_with('USER#')
        )
        print(f"Participants: {participants_response}")
        
        
        participants = []
        user_ids = [participant['SK'].split('#')[1] for participant in participants_response.get('Items', [])]
        print(f"User IDs: {user_ids}")
        if user_ids:
            user_details_response = dynamodb.meta.client.batch_get_item(RequestItems={AUCTION_TABLE: {
                'Keys': [{'PK': f'USER#{user_id}', 'SK': 'METADATA'} for user_id in user_ids]}
            })
            user_details_map = {
                item['PK'].split('#')[1]: item 
                for item in user_details_response.get('Responses', {}).get(AUCTION_TABLE, [])
            }
            print(f"User details: {user_details_map}")
            for participant in participants_response.get('Items', []):
                user_id = participant['SK'].split('#')[1]
                user_details = user_details_map.get(user_id, {})
                participants.append({
                    'userId': user_id,
                    'role': participant.get('role', 'participant'),
                    'email': user_details.get('email', ''),
                    'online': user_details.get('online', False)
                })
        
        # Combine everything into a comprehensive response
        auction_details = {
            'auctionId': auction_id,
            'name': auction.get('name', 'Unknown'),
            'auctionState': auction.get('auctionState', 'unknown'),
            'currentItem': {
                'id': current_item.get('id', ''),
                'expiresAt': current_item.get('expiresAt', ''),
                'price': current_item.get('price', 0),
                'bidder': current_item.get('bidder', '')
            },
            'participants': participants,
            'createdAt': auction.get('createdAt', '')
        }
        
        return respond(None, auction_details)
    except ClientError as e:
        return respond(e.response['Error']['Message'])
    except Exception as e:
        return respond(str(e))

def add_auction_users(event, context):
    """Update the settings of an auction, such as
    the name, state, participants, or settings
    """
    try:
        table = dynamodb.Table(AUCTION_TABLE)
        auction_id = event['pathParameters']['auctionId']
        body = json.loads(event['body'])
        user_ids = body.get('userIds', [])
        user_id = get_user_id(event)
        # Check that the user is the admin
        admin_check = table.get_item(
            Key={'PK': f"AUCTION#{auction_id}", 'SK': 'USER#' + user_id}
        )
        if 'Item' not in admin_check or admin_check['Item'].get('role') != 'admin':
            return respond('You are not the admin of this auction')

        # Check that there are entries for PK Auction and SK User
        for user_id in user_ids:
            table.put_item(
                Item={
                    "PK": f"AUCTION#{auction_id}",
                    "SK": f"USER#{user_id}",
                    "role": "participant",
                    "online": False
                }
            )
            table.put_item(
                Item={
                    "PK": f"USER#{user_id}",
                    "SK": f"AUCTION#{auction_id}",
                    "role": "participant",
                    "online": False
                }
            )
    
        return respond(None, {'auctionId': auction_id, 'updated': body})
    except ClientError as e:
        return respond(e.response['Error']['Message'])
    except Exception as e:
        return respond(str(e))

def place_bid(event, context):
    table = dynamodb.Table(AUCTION_TABLE)
    auction_id = event['pathParameters']['auctionId']
    body = json.loads(event['body'])
    item_id = body['itemId']
    bid_amount = body['bidAmount']
    
    try:
        user_id = get_user_id(event)
        print(f"Placing bid for {user_id} on {item_id} for {bid_amount}")
        response = table.update_item(
            Key={'PK': f"AUCTION#{auction_id}", 'SK': 'CURRENT_ITEM'},
            UpdateExpression='SET bidder = :userId, price = :bidAmount',
            ConditionExpression="(id = :id) AND (attribute_not_exists(bidder) OR price < :bidAmount)",
            ExpressionAttributeValues={
                ':bidAmount': bid_amount,
                ':userId': user_id,
                ':id': item_id
            },
            ReturnValues='ALL_NEW'
        )
        msg = { k: v for k, v in response['Attributes'].items() if k not in ['PK', 'SK'] }
        send_websocket_msg(msg, 'CURRENT_ITEM_UPDATE')
        return respond(None, response['Attributes'])
    except ClientError as e:
        if e.response['Error']['Code'] == 'ConditionalCheckFailedException':
            return respond('Bid not accepted, higher bid already exists')
        return respond(e.response['Error']['Message'])

def start_auction(event, context):
    table = dynamodb.Table(AUCTION_TABLE)
    auction_id = event['pathParameters']['auctionId']
    
    try:
        # Update the auction state to active
        table.update_item(
            Key={ 'PK': f"AUCTION#{auction_id}", 'SK': 'METADATA' },
            UpdateExpression='SET auctionState = :auctionState',
            ExpressionAttributeValues={':auctionState': 'LIVE'}
        )
        # Get the next item
        remaining_items = table.query(
            KeyConditionExpression=Key('PK').eq(f"AUCTION#{auction_id}") & Key('SK').begins_with('ITEM#'),
            FilterExpression=Attr('auctioned').eq(False)
        ).get("Items", [])
        # Pick a random item if there are multiple
        next_item = random.choice(remaining_items)
        expires_at = (datetime.datetime.now() + datetime.timedelta(seconds=30)).isoformat(timespec='seconds') + "Z"
        print(f"Next item: {next_item} [{expires_at}]")
        next_item_id = next_item['SK'].replace("ITEM#", "")
        # Update the current item
        cur_item = table.update_item(
            Key={ "PK": f"AUCTION#{auction_id}", "SK": "CURRENT_ITEM" },
            UpdateExpression="SET id = :id, expiresAt = :expiresAt, price = :price, bidder = :bidder",
            ExpressionAttributeValues={ ":id": next_item_id, ":expiresAt": expires_at, ":price": ITEM_STARTING_PRICE, ":bidder": "" },
            ReturnValues='ALL_NEW'
        )
        msg = {k: v for k, v in cur_item.get('Attributes', {}).items() if k not in ['PK', 'SK']}
        send_websocket_msg(msg, 'CURRENT_ITEM_UPDATE')
        return respond(None, {'auctionId': auction_id, 'auctionState': 'LIVE', 'currentItem': next_item_id, 'expiresAt': expires_at, 'price': ITEM_STARTING_PRICE})
    except ClientError as e:
        return respond(e.response['Error']['Message'])

def add_auction_time(event, context):
    """Set a new expiresAt time for the current item in the auction
    """
    table = dynamodb.Table(AUCTION_TABLE)
    body = json.loads(event['body'])
    
    try:
        auction_id = event['pathParameters']['auctionId']
        expires_at = body['expiresAt']
        res = table.update_item(
            Key={ 'PK': f"AUCTION#{auction_id}", 'SK': 'CURRENT_ITEM' },
            UpdateExpression='SET expiresAt = :expiresAt',
            ExpressionAttributeValues={':expiresAt': expires_at},
            ReturnValues='ALL_NEW'
        )
        res = res['Attributes']
        msg = {k: v for k, v in res.items() if k not in ['PK', 'SK']}
        send_websocket_msg(msg, 'CURRENT_ITEM_UPDATE')
        return respond(None, res)
    except ClientError as e:
        return respond(e.response['Error']['Message'])
    except Exception as e:
        return respond(str(e))

def auction_next(event, context):
    table = dynamodb.Table(AUCTION_TABLE)
    if not (auction_id := event['pathParameters'].get('auctionId')):
        return respond('Missing required path parameter: auctionId')
    try:
        user_id = get_user_id(event)
        # Get the finished block item details
        auctioned_item = table.get_item(
            Key={ "PK": f"AUCTION#{auction_id}", "SK": "CURRENT_ITEM" }
        ).get("Item")
        if not auctioned_item:
            return respond('No current item found')
        # Mark the current item as auctioned for this user and price
        post_auction_item = table.update_item(
            Key={ "PK": f"AUCTION#{auction_id}", "SK": f"ITEM#{auctioned_item['id']}" },
            UpdateExpression="SET auctioned = :auctioned, price = :price, bidder = :bidder, closed_at = :closedAt",
            ExpressionAttributeValues={
                ":auctioned": True,
                ":price": auctioned_item['price'],
                ":bidder": auctioned_item['bidder'],
                ":closedAt": datetime.datetime.now().isoformat(timespec='seconds')
            },
            ReturnValues='ALL_NEW'
        )
        msg = {k: v for k, v in post_auction_item.get('Attributes', {}).items() if k not in ['PK', 'SK']}
        msg["id"] = auctioned_item["id"]
        send_websocket_msg(msg, 'AUCTION_ITEM_FINISHED')
        # Get the next item
        remaining_items = table.query(
            KeyConditionExpression=Key('PK').eq(f"AUCTION#{auction_id}") & Key('SK').begins_with('ITEM#'),
            FilterExpression=Attr('auctioned').eq(False)
        ).get("Items", [])
        # Pick a random item if there are multiple
        next_item = random.choice(remaining_items)
        expires_at = (datetime.datetime.now() + datetime.timedelta(seconds=30)).isoformat(timespec='seconds') + "Z"
        next_item_id = next_item['SK'].replace("ITEM#", "")
        # Update the current item
        res = table.update_item(
            Key={ "PK": f"AUCTION#{auction_id}", "SK": "CURRENT_ITEM" },
            UpdateExpression="SET id = :id, expiresAt = :expiresAt, price = :price, bidder = :bidder",
            ExpressionAttributeValues={ ":id": next_item_id, ":expiresAt": expires_at, ":price": ITEM_STARTING_PRICE, ":bidder": "" },
            ReturnValues='ALL_NEW'
        )
        msg = {k: v for k, v in res.get('Attributes', {}).items() if k not in ['PK', 'SK']}
        send_websocket_msg(msg, 'CURRENT_ITEM_UPDATE')
        return respond(None, msg)
    except ClientError as e:
        return respond(e.response['Error']['Message'])

def get_auction_item_history(event, context):
    try:
        auction_id = event['pathParameters']['auctionId']

        table = dynamodb.Table(AUCTION_TABLE)
        # Get all items for this auction that have been auctioned
        response = table.query(
            KeyConditionExpression="PK = :auctionId AND begins_with(SK, :itemPrefix)",
            FilterExpression="auctioned = :auctioned",
            ExpressionAttributeValues={
                ":auctionId": f"AUCTION#{auction_id}",
                ":itemPrefix": "ITEM#",
                ":auctioned": True
            }
        )
        # Sort the items by the time they were closedAt
        items = list(sorted(response.get('Items', []), key=lambda x: x.get('closed_at', '')))
        return respond(None, items)
    except ClientError as e:
        return respond(e.response['Error']['Message'])
    except Exception as e:
        return respond(str(e))

def send_websocket_msg(data, type):
    gatewayapi = boto3.client('apigatewaymanagementapi', endpoint_url=WS_ENDPOINT)
    # Get Active Connections
    connections_table = dynamodb.Table(CONNECTION_TABLE)
    response = connections_table.scan()
    print(f"Connections: {response}")
    connection_items = response.get('Items', [])
    print(f"Sending message to {len(connection_items)} connections")
    message = { 'type': type, 'data': data }
    for item in connection_items:
        connection_id = item['connectionId']
        try:
            gatewayapi.post_to_connection(ConnectionId=connection_id, Data=json.dumps(message, default=str))
        except ClientError as e:
            if e.response['Error']['Code'] == 'GoneException':
                connection_items.delete_item(Key={'connectionId': connection_id})
            else:
                print(f"Error sending message to {connection_id}: {e}")
        except Exception as e:
            print(f"Error sending message to {connection_id}: {e}")
            traceback.print_exc()

# Define the handler functions for AWS Lambda
handlers = {
    'create_auction': create_auction,
    'get_user_auctions': get_user_auctions,
    'get_auction_details': get_auction_details,
    'get_auction_items': get_auction_items,
    'get_auction_item_history': get_auction_item_history,
    'add_auction_users': add_auction_users,
    'add_auction_time': add_auction_time,
    'place_bid': place_bid,
    'start_auction': start_auction,
    'auction_next': auction_next,
}
