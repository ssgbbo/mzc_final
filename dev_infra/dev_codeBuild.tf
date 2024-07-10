data "aws_security_group" "default" {
  name   = "default"
  vpc_id = aws_vpc.dev_vpc.id
}
data "aws_iam_role" "codebuild_role" {
  name               = "lsb_build_role"
}
# codebuildproject #
resource "aws_codebuild_project" "dev-lsb_build_pjt" {
  name         = "dev-lsb_build_pjt"
  description  = "dev_code_build_project"
  service_role = data.aws_iam_role.codebuild_role.arn

  artifacts {
    type      = "S3"
    location      = data.aws_s3_bucket.lsb-code-bucket.bucket
    path      = "/"
    packaging = "ZIP"
    override_artifact_name = true
  }

  cache {
    type  = "LOCAL"
    modes = ["LOCAL_DOCKER_LAYER_CACHE", "LOCAL_SOURCE_CACHE"]
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD" #Amazon ECR에서 Docker 이미지를 가져올 때 사용
    privileged_mode             = true

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = local.account_id
    }

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.region
    }

    environment_variable {
      name  = "REPOSITORY_URI"
      value = aws_ecr_repository.dev-lsb-ecr.repository_url
    }

    environment_variable {
      name  = "IMAGE_TAG"
      value = "latest"
    }
  }

  vpc_config {
    vpc_id = aws_vpc.dev_vpc.id

    subnets = [
      aws_subnet.dev_private_subnet_1.id,
      aws_subnet.dev_private_subnet_2.id
    ]
    security_group_ids = [
      data.aws_security_group.default.id
    ]
  }
  source_version = "master"  # 브랜치 설정
  source {
    type      = "CODECOMMIT"
    location  = aws_codecommit_repository.dev_lsb_code_ccr.clone_url_http
    buildspec = "dev_buildspec.yaml"
    git_clone_depth = 1
  }

  logs_config {
    cloudwatch_logs {
      group_name = "dev_Build-log-group"
      status     = "ENABLED"
    }
  }
  tags = {
    Name = "dev-lsb_build_pjt"
  }
  depends_on = [aws_vpc.dev_vpc]
}