resource "aws_codedeploy_app" "lsb_codeDeploy" {
  compute_platform = "ECS"
  name             = "lsb_codeDeploy"
}

resource "aws_codedeploy_deployment_group" "lsb_codeDeploy" {
  app_name               = aws_codedeploy_app.lsb_codeDeploy.name
  deployment_group_name  = "lsb-my-deployment-group"
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  service_role_arn       = aws_iam_role.codedeploy_role.arn

  ecs_service {
    cluster_name = aws_ecs_cluster.ecs_cluster.name
    service_name = aws_ecs_service.ecs_service.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_lb_listener.listener_https.arn]
      }
      test_traffic_route {
        listener_arns = [aws_lb_listener.listener_8080.arn]
      }
      target_group {
        name = aws_lb_target_group.target_group.name
      }
      target_group {
        name = aws_lb_target_group.target_group_bluegreen.name
      }
    }
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout    = "CONTINUE_DEPLOYMENT"
    }
    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 10
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }
}

resource "aws_iam_role" "codedeploy_role" {
  name = "lsb_codeDeploy-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "ecs_describe_services_policy" {
  name        = "lsb-ECS_Describe_Services_Policy"
  description = "Allows describing ECS services"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "ecs:DescribeServices",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codedeploy_ecs_describe_services_attachment4" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = aws_iam_policy.ecs_describe_services_policy.arn
}

resource "aws_iam_role_policy_attachment" "AWSCodeDeployRoleForECS4" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}
# policy-ecs-task
resource "aws_iam_role_policy_attachment" "AmazonECSTaskExecutionRolePolicy4" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
# policy-ecs-ecs
resource "aws_iam_role_policy_attachment" "AmazonECS_FullAccess4" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}

# policy-ecr
resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryFullAcces4" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

# deploy
resource "aws_iam_role_policy_attachment" "AWSCodeDeployFullAccess4" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployFullAccess"
}