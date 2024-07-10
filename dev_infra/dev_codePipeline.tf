data "aws_iam_role" "pipe_role" {
  name               = "lsb-pipe-role"
}
# pipeline #
resource "aws_codepipeline" "dev_codepipeline" {
  name     = "dev-prd-lsb-pipeline"
  role_arn = data.aws_iam_role.pipe_role.arn

  artifact_store {
    type     = "S3"
    location = data.aws_s3_bucket.lsb-code-bucket.bucket
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["dev_commit"]

      configuration = {
        RepositoryName = aws_codecommit_repository.dev_lsb_code_ccr.repository_name
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
      input_artifacts  = ["dev_commit"]
      output_artifacts = ["dev_build"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.dev-lsb_build_pjt.name
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
      input_artifacts = ["dev_build"]
      version         = "1"

      configuration = {
        ApplicationName     = aws_codedeploy_app.dev-lsb_codeDeploy.name
        DeploymentGroupName = aws_codedeploy_deployment_group.dev-lsb_codeDeploy.deployment_group_name
        AppSpecTemplateArtifact        = "dev_build"
        AppSpecTemplatePath       = "dev_appspec.yaml"
        TaskDefinitionTemplateArtifact = "dev_build"
        TaskDefinitionTemplatePath    = "dev_taskdef.json"
      }
    }
  }
}