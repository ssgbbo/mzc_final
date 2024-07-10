# 역할-pipe
resource "aws_iam_role" "pipe_role" {
  name               = "lsb-pipe-role"
  assume_role_policy = data.aws_iam_policy_document.pipe_role.json
}
# 정책 - pipe
data "aws_iam_policy_document" "pipe_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}
# policy-pipeline
resource "aws_iam_role_policy_attachment" "AWSCodePipeline_FullAccess3" {
  role       = aws_iam_role.pipe_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodePipeline_FullAccess"
}
# policy-s3
resource "aws_iam_role_policy_attachment" "AmazonS3FullAccess3" {
  role       = aws_iam_role.pipe_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}
# policy-commit 
resource "aws_iam_role_policy_attachment" "AWSCodeCommitFullAccess3" {
  role       = aws_iam_role.pipe_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeCommitFullAccess"
}

# # policy-ecr
resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryFullAcces3" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}
# policy-build
resource "aws_iam_role_policy_attachment" "AWSCodeBuildAdminAccess3" {
  role       = aws_iam_role.pipe_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildAdminAccess"
}

# policy-ecs-task
resource "aws_iam_role_policy_attachment" "AmazonECSTaskExecutionRolePolicy3" {
  role       = aws_iam_role.pipe_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
# policy-ecs-ecs
resource "aws_iam_role_policy_attachment" "AmazonECS_FullAccess3" {
  role       = aws_iam_role.pipe_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}
# policy-ecs-deploy
resource "aws_iam_role_policy_attachment" "AWSCodeDeployRoleForECS3" {
  role       = aws_iam_role.pipe_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}
# deploy
resource "aws_iam_role_policy_attachment" "AWSCodeDeployFullAccess" {
  role       = aws_iam_role.pipe_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployFullAccess"
}

# pipeline #
resource "aws_codepipeline" "codepipeline" {
  name     = "prd-lsb-pipeline"
  role_arn = aws_iam_role.pipe_role.arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.lsb-code-bucket.bucket
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["output_commit_artifacts"]

      configuration = {
        RepositoryName = aws_codecommit_repository.lsb_code_ccr.repository_name
        BranchName     = "master"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["output_commit_artifacts"]
      output_artifacts = ["output_build_artifacts"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.lsb_build_pjt.name
        EnvironmentVariables = jsonencode([
          {
            name  = "AWS_ACCOUNT_ID"
            value = local.account_id
          },
          {
            name  = "AWS_DEFAULT_REGION"
            value = var.region
          },
                    {
            name  = "REPOSITORY_URI"
            value = local.repository_uri
          },
                    {
            name  = "IMAGE_TAG"
            value = "latest"
          }
        ])
      }
    }
  }

 # pipeLine에서 관리자가 직접 승인해주는 단계를 생성합니다
  # stage {
  #   name = "Approve"
  #   action {
  #     name     = "Approval"
  #     category = "Approval"
  #     owner    = "AWS"
  #     provider = "Manual"
  #     version  = "1"
  #   }
  # }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      input_artifacts = ["output_build_artifacts"]
      version         = "1"

      configuration = {
        ApplicationName     = aws_codedeploy_app.lsb_codeDeploy.name
        DeploymentGroupName = aws_codedeploy_deployment_group.lsb_codeDeploy.deployment_group_name
        AppSpecTemplateArtifact        = "output_build_artifacts"
        TaskDefinitionTemplateArtifact = "output_build_artifacts"
      }
    }
  }
}