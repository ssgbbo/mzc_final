# This file describes the Load Balancer resources: ALB, ALB target group, ALB listener

#Defining the Application Load Balancer
resource "aws_alb" "dev_application_load_balancer" {
  name               = "dev-lsb-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.dev_public_subnet_1.id, aws_subnet.dev_public_subnet_2.id]
  security_groups    = [aws_security_group.dev_alb_sg.id]
  tags = {
    Name = "dev-lsb-alb"
  }
}

#Defining the target group and a health check on the application
resource "aws_lb_target_group" "dev_target_group" {
  name        = "dev-lsb-tg"
  port        = var.container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.dev_vpc.id

  deregistration_delay = 10 # Deregistration delay set to 10 seconds (default=300) 배포시간 빠르게.

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 10
    interval            = 30
  }
  tags = {
    Name = "dev-lsb-target-group"
  }
}

resource "aws_lb_target_group" "dev_target_group_bluegreen" {
  name        = "dev-lsb-tg-bluegreen"
  port        = var.container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.dev_vpc.id
  health_check {
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 10
    interval            = 30
  }
  tags = {
    Name = "dev-lsb-target-group-bluegreen"
  }
}

#Defines an HTTP Listener for the ALB
resource "aws_lb_listener" "dev_listener" {
  load_balancer_arn = aws_alb.dev_application_load_balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      protocol = "HTTPS"
      port     = "443"
      status_code = "HTTP_301"
    }
  }
  tags = {
    Name = "dev-lsb-lb-listener"
  }
  depends_on = [ aws_lb_target_group.dev_target_group ]
}

resource "aws_lb_listener" "dev_listener_https" {
  load_balancer_arn = aws_alb.dev_application_load_balancer.arn
  port              = "443"
  protocol          = "HTTPS"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dev_target_group.arn
  }
  ssl_policy       = "ELBSecurityPolicy-2016-08"
  certificate_arn = aws_acm_certificate.dev_cert.arn
  
  tags = {
    Name = "dev-lsb-lb-listener-https"
  }

  depends_on = [ aws_lb_target_group.dev_target_group ]
}

resource "aws_lb_listener" "dev_listener_8080" {
  load_balancer_arn = aws_alb.dev_application_load_balancer.arn
  port              = "8080"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.dev_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dev_target_group_bluegreen.arn
  }
  
  tags = {
    Name = "dev-lsb-lb-listener-https"
  }
  depends_on = [ aws_lb_target_group.dev_target_group ]
}