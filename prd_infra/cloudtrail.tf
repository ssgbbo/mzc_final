# 추적 생성
resource "aws_cloudtrail" "lsb-cloudtrail" {
  name = "lsb-cloudtrail"

  # IAM과 같은 글로벌 이벤트 로깅
  include_global_service_events = true

  # 다중 리전 추적 허용
  is_multi_region_trail = false

  # 이벤트 로그를 저장할 버킷 지정
  s3_bucket_name = aws_s3_bucket.lsb_trail_bucket.id

  # 로그 파일 검증(다이제스트 파일로 s3로 보내질 때 내용 무결성 검증)
  enable_log_file_validation = true

  # cloudwatch logs 활성화
  cloud_watch_logs_role_arn  = aws_iam_role.CloudTrailRoleForCloudWatchLogs.arn
  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.lsb-cloudtrail.arn}:*" # 뒤에 :* 을 꼭 붙여줘야됩니다.

  # 관리 이벤트: 읽기, 쓰기
  event_selector {
    read_write_type = "All"
  }

  depends_on = [
    aws_cloudwatch_log_group.lsb-cloudtrail,
    aws_s3_bucket_policy.lsb_trail_bucket_policy,
    aws_s3_bucket.lsb-code-bucket
  ]
}

output "trail_id" {
  value = aws_cloudtrail.lsb-cloudtrail.id
}

resource "aws_iam_role" "CloudTrailRoleForCloudWatchLogs" {
  name = "CloudTrailRoleForCloudWatchLogs"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# CloudTrail에서 CloudWatch Logs로 이벤트 로그를 보내도록 허용하는 정책 생성
resource "aws_iam_policy" "lsb-cloudtrail-policy" {
  name        = "CloudTrailToCloudWatchLogs"
  path        = "/"
  description = "CloudTrailToCloudWatchLogs"

 policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Effect": "Allow",
     "Action": [
       "logs:CreateLogGroup",
       "logs:CreateLogStream",
       "logs:PutLogEvents"
     ],
     "Resource": "*"
   }
 ]
}
EOF
}

# 해당 정책을 역할에 연결
resource "aws_iam_policy_attachment" "lsb-cloudtrail" {
  name       = "lsb-cloudtrail-poilcy"
  roles      = [aws_iam_role.CloudTrailRoleForCloudWatchLogs.name]
  policy_arn = aws_iam_policy.lsb-cloudtrail-policy.arn
}

resource "aws_cloudwatch_log_group" "lsb-cloudtrail" {
  name = "tf-lsb-cloudtrail-cloudtrail"

  tags = {
    Name = "lsb-cloudtrail-log-group"
  }
}

# S3 cloudtrail 로그 보관용 생성
resource "aws_s3_bucket" "lsb_trail_bucket" {
  bucket = "lsb-cloudtrail-logs-bucket"
  force_destroy = true
}
# S3 versioning 설정 #
resource "aws_s3_bucket_versioning" "lsb_trail_bucket_versioning" {
  bucket = aws_s3_bucket.lsb_trail_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}
# S3 lifecycle 설정 #
resource "aws_s3_bucket_lifecycle_configuration" "versioning-bucket-config" {
  # Must have bucket versioning enabled first
  depends_on = [aws_s3_bucket_versioning.lsb_trail_bucket_versioning]

  bucket = aws_s3_bucket.lsb_trail_bucket.id

  rule {
    id = "config"

    filter {
      prefix = "config/"
    }

    noncurrent_version_transition { # 객체 버전의 비활성화 후 90일 후에 STANDARD_IA로 전환
      noncurrent_days = 90
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition { # 180일 후에 GLACIER로 전환
      noncurrent_days = 180
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration { # 365일 후에 만료
      noncurrent_days = 365
    }

    status = "Enabled"
  }
}
resource "aws_s3_bucket_policy" "lsb_trail_bucket_policy" {
  bucket = aws_s3_bucket.lsb_trail_bucket.id #고유한 이름으로 설정하기 위해.
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AWSCloudTrailAclCheck20150319",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "s3:GetBucketAcl",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.lsb_trail_bucket.id}"
    },
    {
      "Sid": "AWSCloudTrailWrite20150319",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.lsb_trail_bucket.id}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": "bucket-owner-full-control"
        }
      }
    }
  ]
}
POLICY
}
