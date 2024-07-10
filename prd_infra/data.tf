data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  repository_uri = aws_ecr_repository.lsb-ecr.repository_url
}