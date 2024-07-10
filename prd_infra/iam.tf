# ECS 역할 정책 #
# 정책-task #
data "aws_iam_policy_document" "ecs-role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}
# 역할-task #
resource "aws_iam_role" "ecs-role" {
  name               = "lsb-ecs-role"
  assume_role_policy = data.aws_iam_policy_document.ecs-role.json
}

# Policy-ECS #
resource "aws_iam_role_policy_attachment" "AmazonECS_FullAccess" {
  role       = aws_iam_role.ecs-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}
# Policy-ECS-Task #
resource "aws_iam_role_policy_attachment" "AmazonECSTaskExecutionRolePolicy" {
  role       = aws_iam_role.ecs-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "lsb-test-app-ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecsTaskRole" {
  name               = "lsb-ecsTaskRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "ecsTaskRole_policy" {
  role       = aws_iam_role.ecs-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}