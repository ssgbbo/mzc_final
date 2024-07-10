
data "aws_iam_role" "codedeploy_role" {
  name = "lsb_codeDeploy-service-role"
}

resource "aws_codedeploy_app" "dev-lsb_codeDeploy" {
  compute_platform = "ECS"
  name             = "dev-lsb_codeDeploy"
  tags = {
    Name = "dev-lsb_codeDeploy"
  }
}

resource "aws_codedeploy_deployment_group" "dev-lsb_codeDeploy" {
  app_name               = aws_codedeploy_app.dev-lsb_codeDeploy.name
  deployment_group_name  = "dev-lsb-my-deployment-group"
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  service_role_arn       = data.aws_iam_role.codedeploy_role.arn

  ecs_service {
    cluster_name = aws_ecs_cluster.dev_ecs_cluster.name
    service_name = aws_ecs_service.dev_ecs_service.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_lb_listener.dev_listener.arn]
      }
      test_traffic_route {
        listener_arns = [aws_lb_listener.dev_listener_8080.arn]
      }
      target_group {
        name = aws_lb_target_group.dev_target_group.name
      }
      target_group {
        name = aws_lb_target_group.dev_target_group_bluegreen.name
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
  tags = {
    Name = "dev-lsb_codeDeploy_group"
  }
}