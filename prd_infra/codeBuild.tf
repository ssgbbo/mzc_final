data "aws_security_group" "default" {
  name   = "default"
  vpc_id = aws_vpc.vpc.id
}
# Codebuild #
# 역할- Codebuild #
resource "aws_iam_role" "codebuild_role" {
  name               = "lsb_build_role"
  assume_role_policy = data.aws_iam_policy_document.codebuild_role.json
}
# 정책-codebuild #
data "aws_iam_policy_document" "codebuild_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}
# policy-build
resource "aws_iam_role_policy_attachment" "AWSCodeBuildAdminAcces2" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildAdminAccess"
}

resource "aws_iam_role_policy_attachment" "AdministratorAccess2" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# policy-ecr
resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryFullAcces2" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}
# policy-s3
resource "aws_iam_role_policy_attachment" "AmazonS3FullAccess2" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}
# codecommit
resource "aws_iam_role_policy_attachment" "CodeCommitFullAccess2" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeCommitFullAccess"
}
# codepipeline 
resource "aws_iam_role_policy_attachment" "CodePipeline_FullAccess2" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodePipeline_FullAccess"
}
# policy-ecs
resource "aws_iam_role_policy_attachment" "AmazonECS_FullAccess2" {
  role = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}
#policy-ecs-task 
resource "aws_iam_role_policy_attachment" "AmazonECSTaskExecutionRolePolicy2" {
  role = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
# codebuildproject #
resource "aws_codebuild_project" "lsb_build_pjt" {
  name         = "lsb_build_pjt"
  description  = "code_build_project"
  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type      = "S3"
    location      = aws_s3_bucket.lsb-code-bucket.bucket
    name  = "lsb_codebuild_artifacts"
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
      value = aws_ecr_repository.lsb-ecr.repository_url
    }

    environment_variable {
      name  = "IMAGE_TAG"
      value = "latest"
    }
  }

  vpc_config {
    vpc_id = aws_vpc.vpc.id

    subnets = [
      aws_subnet.private_subnet_1.id,
      aws_subnet.private_subnet_2.id
    ]
    security_group_ids = [
      data.aws_security_group.default.id
    ]
  }
  source_version = "master"  # 브랜치 설정
  source {
    type      = "CODECOMMIT"
    location  = aws_codecommit_repository.lsb_code_ccr.clone_url_http
    buildspec = "buildspec.yaml"
  }

  logs_config {
    cloudwatch_logs {
      group_name = "Build-log-group"
      status     = "ENABLED"
    }
  }
  tags = {
    Name = "prd_lsb_build_pjt"
  }
  depends_on = [aws_vpc.vpc]

}