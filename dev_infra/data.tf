data "aws_caller_identity" "current" {}
data "aws_s3_bucket" "lsb-code-bucket" {
  bucket = "lsb-code-bucket"
}
# 기존 IAM 역할 참조
data "aws_iam_role" "ecs-role" {
  name = "lsb-ecs-role"
}

data "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "lsb-test-app-ecsTaskExecutionRole"
}

data "aws_iam_role" "ecsTaskRole" {
  name               = "lsb-ecsTaskRole"
}

locals {
  account_id = data.aws_caller_identity.current.account_id
  repository_uri = aws_ecr_repository.dev-lsb-ecr.repository_url
}