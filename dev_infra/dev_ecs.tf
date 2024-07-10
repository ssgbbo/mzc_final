# This file describes the ECS resources: ECS cluster, ECS task definition, ECS service

#ECS cluster
resource "aws_ecs_cluster" "dev_ecs_cluster" {
  name = var.dev_ecs_cluster_name
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

#The Task Definition used in conjunction with the ECS service
resource "aws_ecs_task_definition" "dev_task_definition" {
  family = "dev_lsb_family"
  #Fargate is used as opposed to EC2, so we do not need to manage the EC2 instances. Fargate is serveless
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = data.aws_iam_role.ecs-role.arn
  task_role_arn            = data.aws_iam_role.ecs-role.arn
  # container definitions describes the configurations for the task
  container_definitions = jsonencode(
    [
      {
        "name" : "dev_lsb_container",
        "image" : "${aws_ecr_repository.dev-lsb-ecr.repository_url}:latest",
        "essential" : true,
        "networkMode" : "awsvpc",
        "portMappings" : [
          {
            "name" : "serivce-80-tcp",
            "containerPort" : var.container_port,
            "hostPort" : var.container_port,
          }
        ],
        "healthCheck" : {
          "command" : ["CMD-SHELL", "curl -f http://localhost:8080/ || exit 1"],
          "interval" : 30,
          "timeout" : 5,
          "startPeriod" : 10,
          "retries" : 3
        },
        "logconfiguration" : {
          "logdriver" : "awslogs",
          "options" : {
            "awslogs-group" : "${aws_cloudwatch_log_group.dev_log_group.name}",
            "awslogs-region" : var.region,
            "awslogs-stream-prefix" : "${aws_cloudwatch_log_stream.dev_log_stream.name}",
          }
        },
        "entryPoint" : []
      }
    ]
  )
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
}

#The ECS service described. This resources allows you to manage tasks
resource "aws_ecs_service" "dev_ecs_service" {
  name                = var.dev_ecs_service_name
  cluster             = aws_ecs_cluster.dev_ecs_cluster.arn
  task_definition     = aws_ecs_task_definition.dev_task_definition.arn
  launch_type         = "FARGATE"
  scheduling_strategy = "REPLICA"
  desired_count       = 2 # the number of tasks you wish to run

  network_configuration {
    subnets          = [aws_subnet.dev_private_subnet_1.id, aws_subnet.dev_private_subnet_2.id]
    assign_public_ip = false
    security_groups  = [aws_security_group.dev_ecs_sg.id, aws_security_group.dev_alb_sg.id]
  }

  # This block registers the tasks to a target group of the loadbalancer.
  load_balancer {
    target_group_arn = aws_lb_target_group.dev_target_group.arn #the target group defined in the alb file
    container_name   = "dev_lsb_container"
    container_port   = var.container_port
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  depends_on = [aws_lb_listener.dev_listener, aws_lb_target_group.dev_target_group]
}

resource "aws_cloudwatch_dashboard" "dev_ecs_dashboard" {
  dashboard_name = "ecs-dashboard"
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric",
        x      = 0,
        y      = 0,
        width  = 12,
        height = 6,
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ServiceName", var.dev_ecs_service_name, "ClusterName", var.dev_ecs_cluster_name, { stat = "Average" }],
            [".", "MemoryUtilization", ".", ".", ".", ".", { stat = "Average" }]
          ],
          region = "us-west-1"
          annotations = {
            horizontal = [
              {
                color = "#ff9896",
                label = "100% CPU",
                value = 100
              },
              {
                color = "#9edae5",
                label = "100% Memory",
                value = 100,
                yAxis = "right"
              },
            ]
          }
          yAxis = {
            left = {
              min = 0
            }
            right = {
              min = 0
            }
          }
          period = 300,
          title  = "ECS dev Service Metrics",
        },
      },
    ],
  })
  depends_on = [aws_ecs_service.dev_ecs_service]
}
# CloudWatch log_group & log_stream
resource "aws_cloudwatch_log_group" "dev_log_group" {
  name              = "dev-lsb_task_log_group"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_stream" "dev_log_stream" {
  name           = "dev-lsb_log_stream"
  log_group_name = aws_cloudwatch_log_group.dev_log_group.name
}
