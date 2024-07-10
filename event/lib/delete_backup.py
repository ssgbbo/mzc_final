import boto3
import os
import json
import requests
from datetime import datetime, timedelta

dynamodb = boto3.client('dynamodb')
s3 = boto3.client('s3')
table_name = os.environ['TABLE_NAME']
bucket_name = os.environ['BUCKET_NAME']
slack_webhook_url = os.environ['SLACK_WEBHOOK_URL']

def lambda_handler(event, context):
    logs = []
    logs.append("Lambda function started.")

    try:
        # Scan the DynamoDB table
        logs.append(f"Scanning DynamoDB table {table_name}.")
        response = dynamodb.scan(TableName=table_name)
        logs.append("DynamoDB table scan successful.")
    except dynamodb.exceptions.ResourceNotFoundException:
        error_message = f"Table {table_name} not found."
        logs.append(error_message)
        print("\n".join(logs))  # Log to CloudWatch
        notify_slack(slack_webhook_url, "\n".join(logs))
        return {
            'statusCode': 500,
            'body': json.dumps({'message': error_message, 'logs': logs})
        }
    except Exception as e:
        error_message = f"Failed to scan DynamoDB table: {str(e)}"
        logs.append(error_message)
        print("\n".join(logs))  # Log to CloudWatch
        notify_slack(slack_webhook_url, "\n".join(logs))
        return {
            'statusCode': 500,
            'body': json.dumps({'message': error_message, 'logs': logs})
        }

    # Generate the backup file name
    timestamp = (datetime.now() + timedelta(hours=9)).strftime('%Y%m%d%H%M%S')
    backup_file_name = f"backup-{timestamp}.json"

    try:
        # Convert the DynamoDB items to JSON
        logs.append("Converting DynamoDB items to JSON.")
        items = response['Items']
        backup_data = json.dumps(items, ensure_ascii=False)
        logs.append("DynamoDB items converted to JSON.")
    except Exception as e:
        error_message = f"Failed to convert items to JSON: {str(e)}"
        logs.append(error_message)
        print("\n".join(logs))  # Log to CloudWatch
        notify_slack(slack_webhook_url, "\n".join(logs))
        return {
            'statusCode': 500,
            'body': json.dumps({'message': error_message, 'logs': logs})
        }

    try:
        # Upload the JSON to S3
        logs.append(f"Uploading backup to S3 bucket {bucket_name} with key {backup_file_name}.")
        s3.put_object(Bucket=bucket_name, Key=backup_file_name, Body=backup_data)
        logs.append(f"Backup uploaded to S3 as {backup_file_name}.")
    except Exception as e:
        error_message = f"Failed to upload backup to S3: {str(e)}"
        logs.append(error_message)
        print("\n".join(logs))  # Log to CloudWatch
        notify_slack(slack_webhook_url, "\n".join(logs))
        return {
            'statusCode': 500,
            'body': json.dumps({'message': error_message, 'logs': logs})
        }

    notify_slack(slack_webhook_url, "\n".join(logs))

    # Table backup is successful, now delete all items in the table
    try:
        logs.append(f"Deleting all items in DynamoDB table {table_name}.")
        delete_all_items(dynamodb, table_name, logs)
        logs.append("All items deleted from DynamoDB table.")
        print("\n".join(logs))  # Log to CloudWatch
        notify_slack(slack_webhook_url, "\n".join(logs))
    except Exception as e:
        error_message = f"Failed to delete all items from DynamoDB table: {str(e)}"
        logs.append(error_message)
        print("\n".join(logs))  # Log to CloudWatch
        notify_slack(slack_webhook_url, "\n".join(logs))
        return {
            'statusCode': 500,
            'body': json.dumps({'message': error_message, 'logs': logs})
        }

    # Send notification to Slack
    success_message = f"Backup completed for {table_name}, uploaded to S3 as {backup_file_name}, and all items deleted from the table"
    logs.append(success_message)
    print("\n".join(logs))  # Log to CloudWatch

    return {
        'statusCode': 200,
        'body': json.dumps({'message': 'Backup completed, all items deleted from the table', 'backup_file': backup_file_name, 'logs': logs})
    }

def delete_all_items(dynamodb, table_name, logs):
    dynamodb_resource = boto3.resource('dynamodb')
    table = dynamodb_resource.Table(table_name)
    scan = table.scan(ProjectionExpression='room_id, #t', ExpressionAttributeNames={'#t': 'timestamp'})
    item_count = len(scan['Items'])
    if item_count == 0:
        logs.append("No items found in the table to delete.")
        return
    with table.batch_writer() as batch:
        for item in scan['Items']:
            batch.delete_item(Key={'room_id': item['room_id'], 'timestamp': item['timestamp']})
    logs.append(f"Deleted {item_count} items from the table.")

def notify_slack(webhook_url, message):
    slack_message = {'text': message}
    try:
        response = requests.post(webhook_url, data=json.dumps(slack_message), headers={'Content-Type': 'application/json'})
        response.raise_for_status()
    except requests.exceptions.RequestException as e:
        print(f"Failed to send notification to Slack: {str(e)}")
