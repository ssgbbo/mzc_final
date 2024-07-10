# Codecommit #
# Codecommit-repository #
resource "aws_codecommit_repository" "dev_lsb_code_ccr" {
  repository_name = "dev_lsb_code_ccr"
  description     = "Dev Repository for CodeCommit"
  default_branch  = "master"
  tags = {
    Name = "dev-lsb-code-ccr"
  }
}