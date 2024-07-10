import boto3
import os
import json
import requests
import logging

# 로거 설정
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    dynamodb = boto3.resource('dynamodb')
    s3 = boto3.client('s3')
    table_name = os.environ['TABLE_NAME']
    bucket_name = os.environ['BUCKET_NAME']
    slack_webhook_url = os.environ['SLACK_WEBHOOK_URL']
    backup_file_name = event.get('backup_file_name', '')  # 이벤트 인자로 전달받음

    logs = []

    if not backup_file_name:
        error_message = "Backup file name not provided in the event."
        logs.append(error_message)
        notify_slack(slack_webhook_url, "\n".join(logs))
        return {
            'statusCode': 400,
            'body': json.dumps({'message': error_message, 'logs': logs})
        }

    try:
        logger.info(f"Downloading backup file {backup_file_name} from S3 bucket {bucket_name}.")
        backup_file = s3.get_object(
            Bucket=bucket_name,
            Key=backup_file_name
        )
        backup_data = json.loads(backup_file['Body'].read().decode('utf-8'))
        logs.append("Backup file downloaded and loaded from S3.")
        logger.info("Backup file downloaded and loaded from S3.")
    except Exception as e:
        error_message = f"Failed to download and load backup file from S3: {str(e)}"
        logs.append(error_message)
        notify_slack(slack_webhook_url, "\n".join(logs))
        return {
            'statusCode': 500,
            'body': json.dumps({'message': error_message, 'logs': logs})
        }

    try:
        # Restore the items to DynamoDB
        table = dynamodb.Table(table_name)
        with table.batch_writer() as batch:
            for item in backup_data:
                batch.put_item(Item=item)
        logs.append("Items restored to DynamoDB table.")
    except Exception as e:
        error_message = f"Failed to restore items to DynamoDB table: {str(e)}"
        logs.append(error_message)
        notify_slack(slack_webhook_url, "\n".join(logs))
        return {
            'statusCode': 500,
            'body': json.dumps({'message': error_message, 'logs': logs})
        }

    # Send notification to Slack
    success_message = f"Restore completed for {table_name} from S3 backup file {backup_file_name}"
    logs.append(success_message)
    notify_slack(slack_webhook_url, "\n".join(logs))

    return {
        'statusCode': 200,
        'body': json.dumps({'message': 'Restore completed from S3 backup', 'logs': logs})
    }

def notify_slack(webhook_url, message):
    slack_message = {
        'text': message
    }
    try:
        response = requests.post(webhook_url, data=json.dumps(slack_message), headers={'Content-Type': 'application/json'})
        if response.status_code != 200:
            raise ValueError(f"Request to Slack returned an error {response.status_code}, the response is:\n{response.text}")
    except Exception as e:
        print(f"Failed to send Slack notification: {str(e)}")


# aws lambda invoke --function-name restore_db_function --payload '{"backup_file_name": "backup-20240611043002.json"}' --cli-binary-format raw-in-base64-out output.txt