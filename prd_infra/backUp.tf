# 백업 데이터를 저장할 백업 금고를 생성합니다.
resource "aws_backup_vault" "lsb_book_db_backup" {
  name = "lsb_book_db_backup_vault"
  lifecycle {
    prevent_destroy = false
  }
}

# 백업 계획을 생성합니다.
resource "aws_backup_plan" "lsb_book_db_backup" {
  name = "lsb_book_db_backup_plan"

  # 백업 규칙을 정의합니다.
  rule {
    rule_name         = "daily-backup" # 규칙 이름
    target_vault_name = aws_backup_vault.lsb_book_db_backup.name # 백업 데이터를 저장할 백업 금고 이름
    schedule          = "cron(0 15 * * ? *)" # 매일 서울 시간 자정 (00:00) 실행하는 스케줄 (UTC 기준 + 9시간 = 한국 시간)
    start_window      = 60 # 백업 시작 시간을 위한 윈도우 다음 시간 내에 시작 (분 단위)
    completion_window = 180 # 백업 완료 시간을 위한 윈도우 다음 시간 내에 완료 (분 단위)
    
    # 백업 데이터의 수명 주기를 정의합니다.
    lifecycle {
      cold_storage_after = 60 # 60일 후 백업 데이터를 콜드 스토리지로 이동
      delete_after = 180 # 180일 후 백업 데이터를 삭제
    }
  }
}

# 백업 선택을 설정하여 백업할 리소스를 정의합니다.
resource "aws_backup_selection" "lsb_book_db_backup" {
  iam_role_arn = aws_iam_role.lsb_book_db_backup.arn # 백업 작업을 수행할 IAM 역할의 ARN
  name         = "lsb_book_db_backup_selection" # 백업 선택 이름
  plan_id      = aws_backup_plan.lsb_book_db_backup.id # 백업 계획 ID

  # 백업할 DynamoDB 테이블의 ARN을 지정합니다.
  resources = [
    aws_dynamodb_table.lsb_table.arn,
  ]
}

# 백업 작업을 수행할 수 있도록 AWS Backup 서비스에 권한을 부여하는 IAM 역할을 생성합니다.
resource "aws_iam_role" "lsb_book_db_backup" {
  name = "lsb_book_db_backup_role"

  # IAM 역할의 신뢰 정책을 정의합니다.
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "backup.amazonaws.com" # AWS Backup 서비스에 역할을 맡길 수 있는 권한 부여
        }
      }
    ]
  })
}

# IAM 역할에 필요한 권한 정책을 첨부합니다.
resource "aws_iam_role_policy_attachment" "lsb_book_db_backup" {
  role       = aws_iam_role.lsb_book_db_backup.name # IAM 역할 이름
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup" # 백업을 위한 IAM 정책 ARN
}
