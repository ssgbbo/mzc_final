resource "aws_s3_bucket" "db_backup_lambda" {
  bucket = "lsb-dynamodb-chat-backup"
  force_destroy = true
}

resource "aws_s3_object" "backup_db_zip" {
  bucket = aws_s3_bucket.db_backup_lambda.bucket
  key    = "backup_db.zip"
  source = "backup_db.zip"
}

locals {
  aws_backup_cp_command = "aws s3 cp backup_db.zip s3://lsb-dynamodb-chat-backup/"
}

resource "null_resource" "aws_backup_cp_command" {
  provisioner "local-exec" {
    command = local.aws_backup_cp_command
  }
  triggers = {
    "run_at" = timestamp()
  }
  depends_on = [aws_s3_bucket.db_backup_lambda]
}

resource "aws_iam_role" "lsb_backup_lambda_role" {
  name = "lsb_backup_lambda_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb_policy" {
  role       = aws_iam_role.lsb_backup_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_s3_policy" {
  role       = aws_iam_role.lsb_backup_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lsb_backup_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "backup_db_function" {
  s3_bucket        = aws_s3_bucket.db_backup_lambda.id
  s3_key           = aws_s3_object.backup_db_zip.id
  function_name    = "backup_db_function"
  role             = aws_iam_role.lsb_backup_lambda_role.arn
  handler          = "backup_db.lambda_handler"
  runtime          = "python3.10"

  environment {
    variables = {
      TABLE_NAME = "demo-serverless-chat-dev-chat-messages-1"
      BUCKET_NAME = aws_s3_bucket.db_backup_lambda.bucket
      SLACK_WEBHOOK_URL = "https://hooks.slack.com/services/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"
      LAMBDA_FUNCTION_NAME = "demo-serverless-chat_dev_1_chat_handleStream"
    }
  }
}

resource "aws_cloudwatch_event_rule" "backup_schedule" {
  name                = "backup_schedule"
  description         = "Backup DynamoDB table every day at UTC time 16 - Korea time am 1"
  schedule_expression = "cron(0 16 * * ? *)"
  # schedule_expression = "cron(0/30 * * * ? *)"
  # schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "backup_target" {
  rule = aws_cloudwatch_event_rule.backup_schedule.name
  arn  = aws_lambda_function.backup_db_function.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda" {
  statement_id  = "AllowEventBridgeInvokeBackup"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.backup_db_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.backup_schedule.arn
}

output "backup_lambda_arn" {
  value = aws_lambda_function.backup_db_function.arn
}