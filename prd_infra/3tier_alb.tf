# 애플리케이션 로드 밸런서를 정의합니다
resource "aws_alb" "application_load_balancer" {
  name               = "prd-lsb-alb" # 로드 밸런서의 이름
  internal           = false # 내부 로드 밸런서 여부 (외부에 공개)
  load_balancer_type = "application" # 로드 밸런서 유형 (애플리케이션 로드 밸런서)
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id] # 로드 밸런서를 배치할 서브넷
  security_groups    = [aws_security_group.alb_sg.id] # 로드 밸런서에 연결할 보안 그룹
  tags = {
    Name = "prd-lsb-alb" # 태그 설정
  }
}

# 대상 그룹과 애플리케이션의 헬스 체크를 정의합니다
resource "aws_lb_target_group" "target_group" {
  name        = "prd-lsb-tg" # 대상 그룹의 이름
  port        = var.container_port # 대상 그룹의 포트
  protocol    = "HTTP" # 대상 그룹의 프로토콜
  target_type = "ip" # 대상 타입 (IP 주소)
  vpc_id      = aws_vpc.vpc.id # VPC ID

  deregistration_delay = 10 # 등록 해제 지연 시간 10초로 설정 (기본값 = 300초)

  health_check {
    path                = "/health" # 헬스 체크 경로
    protocol            = "HTTP" # 헬스 체크 프로토콜
    matcher             = "200" # 헬스 체크 매처 (200 응답 코드)
    port                = "traffic-port" # 헬스 체크 포트
    healthy_threshold   = 2 # 헬스 체크 성공 임계값
    unhealthy_threshold = 2 # 헬스 체크 실패 임계값
    timeout             = 10 # 헬스 체크 타임아웃
    interval            = 30 # 헬스 체크 간격
  }
  tags = {
    Name = "prd-lsb-target-group" # 태그 설정
  }
}

# 블루/그린 배포를 위한 대상 그룹과 헬스 체크를 정의합니다
resource "aws_lb_target_group" "target_group_bluegreen" {
  name        = "prd-lsb-tg-bluegreen" # 대상 그룹의 이름
  port        = var.container_port # 대상 그룹의 포트
  protocol    = "HTTP" # 대상 그룹의 프로토콜
  target_type = "ip" # 대상 타입 (IP 주소)
  vpc_id      = aws_vpc.vpc.id # VPC ID

  health_check {
    path                = "/health" # 헬스 체크 경로
    protocol            = "HTTP" # 헬스 체크 프로토콜
    matcher             = "200" # 헬스 체크 매처 (200 응답 코드)
    port                = "traffic-port" # 헬스 체크 포트
    healthy_threshold   = 2 # 헬스 체크 성공 임계값
    unhealthy_threshold = 2 # 헬스 체크 실패 임계값
    timeout             = 10 # 헬스 체크 타임아웃
    interval            = 30 # 헬스 체크 간격
  }
  tags = {
    Name = "prd-lsb_target_group_bluegreen" # 태그 설정
  }
}

# ALB를 위한 HTTP 리스너를 정의합니다
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_alb.application_load_balancer.arn # 로드 밸런서 ARN
  port              = "80" # 리스너 포트
  protocol          = "HTTP" # 리스너 프로토콜

  default_action {
    type = "redirect"

    redirect {
      protocol    = "HTTPS"
      port        = "443"
      status_code = "HTTP_301"
    }
  }
  tags = {
    Name = "prd-lsb-lb-80-listener" # 태그 설정
  }
  depends_on = [aws_lb_target_group.target_group] # 의존성 설정
}

# ALB를 위한 HTTPS 리스너를 정의합니다
resource "aws_lb_listener" "listener_https" {
  load_balancer_arn = aws_alb.application_load_balancer.arn # 로드 밸런서 ARN
  port              = "443" # 리스너 포트
  protocol          = "HTTPS" # 리스너 프로토콜

  default_action {
    type             = "forward" # 기본 액션 타입 (전달)
    target_group_arn = aws_lb_target_group.target_group.arn # 대상 그룹 ARN
  }

  ssl_policy       = "ELBSecurityPolicy-2016-08" # SSL 정책
  certificate_arn  = aws_acm_certificate.cert.arn # 인증서 ARN
  
  tags = {
    Name = "prd-lsb-lb_listener_https" # 태그 설정
  }

  depends_on = [aws_lb_target_group.target_group] # 의존성 설정
}

# ALB를 위한 포트 8080 리스너를 정의합니다
resource "aws_lb_listener" "listener_8080" {
  load_balancer_arn = aws_alb.application_load_balancer.arn # 로드 밸런서 ARN
  port              = "8080" # 리스너 포트
  protocol          = "HTTPS" # 리스너 프로토콜

  default_action {
    type             = "forward" # 기본 액션 타입 (전달)
    target_group_arn = aws_lb_target_group.target_group_bluegreen.arn # 대상 그룹 ARN
  }
  ssl_policy       = "ELBSecurityPolicy-2016-08" # SSL 정책
  certificate_arn  = aws_acm_certificate.cert.arn # 인증서 ARN
  
  tags = {
    Name = "prd-lsb-lb_listener_8080" # 태그 설정
  }

  depends_on = [aws_lb_target_group.target_group_bluegreen] # 의존성 설정
}

# # WAF WebACL을 정의합니다
# resource "aws_wafv2_web_acl" "web_acl" {
#   name        = "prd-lsb-web-acl"
#   scope       = "REGIONAL" # 사용 범위 (REGIONAL or CLOUDFRONT)
#   description = "Web ACL for the application load balancer"
#   default_action {
#     allow {}
#   }

#   rule {
#     name     = "AWS-AWSManagedRulesCommonRuleSet"
#     priority = 1

#     override_action {
#       none {}
#     }

#     statement {
#       managed_rule_group_statement {
#         name        = "AWSManagedRulesCommonRuleSet"
#         vendor_name = "AWS"
#       }
#     }

#     visibility_config {
#       cloudwatch_metrics_enabled = true
#       metric_name                = "AWSManagedRulesCommonRuleSet"
#       sampled_requests_enabled   = true
#     }
#   }

#   visibility_config {
#     cloudwatch_metrics_enabled = true
#     metric_name                = "webACL"
#     sampled_requests_enabled   = true
#   }
# }

# # ALB에 WAF WebACL을 연결합니다
# resource "aws_wafv2_web_acl_association" "web_acl_association" {
#   resource_arn = aws_alb.application_load_balancer.arn
#   web_acl_arn  = aws_wafv2_web_acl.web_acl.arn
# }