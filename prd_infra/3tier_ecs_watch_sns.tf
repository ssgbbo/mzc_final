# This file describes the ECS resources: ECS cluster, ECS task definition, ECS service

#ECS cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.ecs_cluster_name
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

#The Task Definition used in conjunction with the ECS service
resource "aws_ecs_task_definition" "task_definition" {
  family = "lsb_family"
  #Fargate is used as opposed to EC2, so we do not need to manage the EC2 instances. Fargate is serveless
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs-role.arn
  task_role_arn            = aws_iam_role.ecs-role.arn
  # container definitions describes the configurations for the task
  container_definitions = jsonencode(
    [
      {
        "name" : "lsb_container",
        "image" : "${aws_ecr_repository.lsb-ecr.repository_url}:latest",
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
            "awslogs-group" : "${aws_cloudwatch_log_group.log_group.name}",
            "awslogs-region" : var.region,
            "awslogs-stream-prefix" : "${aws_cloudwatch_log_stream.log_stream.name}",
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
resource "aws_ecs_service" "ecs_service" {
  name                = var.ecs_service_name
  cluster             = aws_ecs_cluster.ecs_cluster.arn
  task_definition     = aws_ecs_task_definition.task_definition.arn
  launch_type         = "FARGATE"
  scheduling_strategy = "REPLICA"
  desired_count       = 2 # the number of tasks you wish to run

  network_configuration {
    subnets          = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
    assign_public_ip = false
    security_groups  = [aws_security_group.ecs_sg.id, aws_security_group.alb_sg.id]
  }

  # This block registers the tasks to a target group of the loadbalancer.
  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn #the target group defined in the alb file
    container_name   = "lsb_container"
    container_port   = var.container_port
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  depends_on = [aws_lb_listener.listener, aws_lb_target_group.target_group]
}

# 오토스케일링 대상 정의
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 4
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.ecs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  depends_on = [aws_ecs_service.ecs_service]
}

# CPU 사용률 기반 오토스케일링 정책
resource "aws_appautoscaling_policy" "ecs_policy_cpu" {
  name               = "cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = 60.0
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

# Memory 사용률 기반 오토스케일링 정책
resource "aws_appautoscaling_policy" "ecs_policy_memory" {
  name               = "memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = 60.0
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

# CloudWatch log_group & log_stream
resource "aws_cloudwatch_log_group" "log_group" {
  name              = "lsb_task_log_group"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_stream" "log_stream" {
  name           = "lsb_log_stream"
  log_group_name = aws_cloudwatch_log_group.log_group.name
}

resource "aws_cloudwatch_dashboard" "ecs_dashboard" {
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
            ["AWS/ECS", "CPUUtilization", "ServiceName", var.ecs_service_name, "ClusterName", var.ecs_cluster_name, { stat = "Average" }],
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
          title  = "ECS Service Metrics",
        },
      },
    ],
  })
  depends_on = [aws_ecs_service.ecs_service]
}

# ECS CloudAlarm metric - CPU #
resource "aws_cloudwatch_metric_alarm" "ecs_service_cpu_alarm" {
  alarm_name          = "prd-lsb-ecs-service-cpu-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 60  # 알람이 발생할 임계값을 60으로 설정
  actions_enabled     = true
  alarm_description   = "This will alarm if ECS service CPU utilization is greater than or equal to 60%"

  dimensions = {
    ServiceName = var.ecs_service_name
    ClusterName = var.ecs_cluster_name
  }
  alarm_actions = [aws_sns_topic.sns_topic.arn]
}

# SNS Topic 생성 #
resource "aws_sns_topic" "sns_topic" {
  name         = "sns-topic"
  display_name = "SNS Topic"
}

# SNS 구독 생성 #
resource "aws_sns_topic_subscription" "example_subscription" {
  topic_arn = aws_sns_topic.sns_topic.arn
  protocol  = "email"
  endpoint  = "ssgbbo@gmail.com" # 이메일 주소로 변경
}

# ECS CloudAlarm metric - Memory #
resource "aws_cloudwatch_metric_alarm" "ecs_service_memory_alarm" {
  alarm_name          = "prd-lsb-ecs-service-memory-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 60  # 알람이 발생할 임계값을 60으로 설정
  actions_enabled     = true
  alarm_description   = "This will alarm if ECS service memory utilization is greater than or equal to 60%"

  dimensions = {
    ServiceName = var.ecs_service_name
    ClusterName = var.ecs_cluster_name
  }
  alarm_actions = [aws_sns_topic.sns_topic.arn]
}


# Policy - cloudwatch_logs #
resource "aws_iam_role_policy_attachment" "CloudWatchLogsFullAccess" {
  role       = aws_iam_role.ecs-role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_role_policy_attachment" "CloudWatchReadOnlyAccess" {
  role       = aws_iam_role.ecs-role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "AmazonAPIGatewayPushToCloudWatchLogs" {
  role       = aws_iam_role.ecs-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}
