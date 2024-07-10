# S3 생성 #
resource "aws_s3_bucket" "lsb-code-bucket" {
  bucket = "lsb-code-bucket"
  force_destroy = true
}
# S3 역할 #
resource "aws_iam_role" "lsb-s3-codeartifact-role" {
  name               = "lsb-s3-codeartifact-role"
  assume_role_policy = data.aws_iam_policy_document.lsb-s3-codeartifact-role.json
}
# S3 정책 #
data "aws_iam_policy_document" "lsb-s3-codeartifact-role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }
}
# S3 정책-역할 연결 #
resource "aws_iam_role_policy_attachment" "AmazonS3FullAccess" {
  role       = aws_iam_role.lsb-s3-codeartifact-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# Create an SNS topic for notifications
resource "aws_sns_topic" "s3_notifications" {
  name = "s3-lifecycle-notifications"
}

# Create an SNS topic subscription
resource "aws_sns_topic_subscription" "s3_notifications_email" {
  topic_arn = aws_sns_topic.s3_notifications.arn
  protocol  = "email"
  endpoint  = "ssgbbo@gmail.com"
}

# IAM policy for accessing the bucket
resource "aws_iam_policy" "s3_access_policy" {
  name        = "S3AccessPolicy"
  description = "IAM policy to access S3 bucket"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": "arn:aws:s3:::lsb-code-bucket/*"
    }
  ]
}
POLICY
}

# IAM role for accessing the bucket
resource "aws_iam_role" "s3_access_role" {
  name = "MyS3AccessRole"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

# Attach the policy to a user or role
resource "aws_iam_role_policy_attachment" "s3_access_role_attachment" {
  role       = aws_iam_role.s3_access_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}