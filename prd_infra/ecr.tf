# This file describes the ECR resources: ECR repo, ECR policy, resources to build and push image

#Creation of the ECR repo
resource "aws_ecr_repository" "lsb-ecr" {
  name                 = "prd-lsb-ecr"
  image_tag_mutability = "MUTABLE" #이미지 태그 중복일 경우 자동 덮어쓰기
  force_delete = true
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "lsb-ecr"
  }
}

#The ECR policy describes the management of images in the repo
resource "aws_ecr_lifecycle_policy" "ecr_policy" {
  repository = aws_ecr_repository.lsb-ecr.name
  policy     = local.ecr_policy
}

#This is the policy defining the rules for images in the repo
locals {
  ecr_policy = jsonencode({
    "rules" : [
      {
        "rulePriority" : 1,
        "description" : "Expire images older than 14 days",
        "selection" : {
          "tagStatus" : "any",
          "countType" : "sinceImagePushed",
          "countUnit" : "days",
          "countNumber" : 14
        },
        "action" : {
          "type" : "expire"
        }
      }
    ]
  })

  depends_on = [aws_ecr_repository.lsb-ecr]
}

#The commands below are used to build and push a docker image of the application in the app folder
locals {
  docker_login_command = "aws ecr get-login-password --region ${var.region}| docker login --username AWS --password-stdin ${local.account_id}.dkr.ecr.${var.region}.amazonaws.com"
  docker_build_command = "docker build -t ${aws_ecr_repository.lsb-ecr.name} ./app"
  docker_tag_command   = "docker tag ${aws_ecr_repository.lsb-ecr.name}:latest ${local.account_id}.dkr.ecr.${var.region}.amazonaws.com/${aws_ecr_repository.lsb-ecr.name}:latest"
  docker_push_command  = "docker push ${local.account_id}.dkr.ecr.${var.region}.amazonaws.com/${aws_ecr_repository.lsb-ecr.name}:latest"
}

#This resource authenticates you to the ECR service
resource "null_resource" "docker_login" {
  provisioner "local-exec" {
    command = local.docker_login_command
  }
  triggers = {
    "run_at" = timestamp()
  }
  depends_on = [aws_ecr_repository.lsb-ecr]
}

#This resource builds the docker image from the Dockerfile in the app folder
resource "null_resource" "docker_build" {
  provisioner "local-exec" {
    command = local.docker_build_command
  }
  triggers = {
    "run_at" = timestamp()
  }
  depends_on = [null_resource.docker_login]
}

#This resource tags the image 
resource "null_resource" "docker_tag" {
  provisioner "local-exec" {
    command = local.docker_tag_command
  }
  triggers = {
    "run_at" = timestamp()
  }
  depends_on = [null_resource.docker_build]
}

#This resource pushes the docker image to the ECR repo
resource "null_resource" "docker_push" {
  provisioner "local-exec" {
    command = local.docker_push_command
  }
  triggers = {
    "run_at" = timestamp()
  }
  depends_on = [null_resource.docker_tag]
}