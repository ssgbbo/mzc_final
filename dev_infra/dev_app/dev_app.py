from flask import Flask, render_template, request, redirect, url_for
import boto3
import datetime
import requests
import json


app = Flask(__name__)

dynamodb = boto3.resource('dynamodb')

def createTable():
    table = dynamodb.create_table(
        TableName='dev-leavedays',
        KeySchema=[
            {
                'AttributeName': 'leave_id',
                'KeyType': 'HASH'
            }
        ],
        AttributeDefinitions=[
            {
                'AttributeName': 'leave_id',
                'AttributeType': 'N'
            }
        ],
        ProvisionedThroughput={
            'ReadCapacityUnits': 5,
            'WriteCapacityUnits': 5
        }
    )
    return table

def addLeaveDay(name, from_date, to_date):
    leave_id = int(datetime.datetime.now().timestamp())
    item = {
        'leave_id': leave_id,
        'name': name,
        'from_date': from_date,
        'to_date': to_date
    }
    table = dynamodb.Table('dev-leavedays')
    table.put_item(Item=item)

def getLeaveDays():
    table = dynamodb.Table('dev-leavedays')
    response = table.scan()
    return response['Items']

def deletLeaveDay(leave_id):
    table = dynamodb.Table('dev-leavedays')
    table.delete_item(
        Key={
            'leave_id': leave_id
        }
    ) 


@app.route('/', methods=['GET', 'POST'])
def index():
    if request.method == 'POST':
        from_date = request.form['from_date']
        to_date = request.form['to_date']
        name = request.form['user_name']

        #insert into dynamodb
        addLeaveDay(name, from_date, to_date)

        return redirect(url_for('index'))

    # leave_days = get_all_leave_days()
    leave_days = getLeaveDays()

    # 클라이언트 IP 주소 가져오기
    client_ip = request.remote_addr

    # Fargate 메타데이터 API에서 컨테이너 IP 주소 가져오기
    metadata_url = 'http://169.254.170.2/v2/metadata'
    response = requests.get(metadata_url)
    metadata = response.json()

    availability_zone = metadata.get('AvailabilityZone')

    return render_template('index.html', leave_days=leave_days, availability_zone=availability_zone)


@app.route('/delete/<int:leave_id>', methods=['POST','DELETE'])
def delete_leave(leave_id):
    if request.method == 'POST' or request.method == 'DELETE':
        deletLeaveDay(leave_id)
    return redirect(url_for('index'))

@app.route('/health', methods=['GET'])
def health_check():
    return "Healthy"

if __name__ == '__main__':
    # create_tables()
    app.run(host='0.0.0.0', port=8080)
