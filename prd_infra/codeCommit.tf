# Codecommit #
# Codecommit-repository #
resource "aws_codecommit_repository" "lsb_code_ccr" {
  repository_name = "lsb_code_ccr"
  description     = "Repository for CodeCommit"
  default_branch  = "master"
}

# IAM 역할 정의
resource "aws_iam_role" "lsb_codecommit_role" {
  name = "lsb-codecommit-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# IAM 역할에 정책 연결
resource "aws_iam_role_policy_attachment" "AWSCodeCommitFullAccess1" {
  role       = aws_iam_role.lsb_codecommit_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeCommitFullAccess"
}

# Output for IAM Role
output "lsb_codecommit_role_arn" {
  value = aws_iam_role.lsb_codecommit_role.arn
}

# Output for CodeCommit Repository
output "codecommit_repository_clone_url_http" {
  value = aws_codecommit_repository.lsb_code_ccr.clone_url_http
}

output "codecommit_repository_clone_url_ssh" {
  value = aws_codecommit_repository.lsb_code_ccr.clone_url_ssh
}