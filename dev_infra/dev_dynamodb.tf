resource "aws_dynamodb_table" "dev_lsb_table" {
  name         = "dev-leavedays"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "leave_id"
  attribute {
    name = "leave_id"
    type = "N"
  }
}

resource "aws_vpc_endpoint" "dev_dynamodb_Endpoint" {
  vpc_id            = aws_vpc.dev_vpc.id
  service_name      = "com.amazonaws.us-west-1.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.dev_private_rt1.id]
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : "*",
        "Action" : "*",
        "Resource" : "*"
      }
    ]
  })
  tags = {
    Name = "dev-lsb-vpc-db-endpoint"
  }
  depends_on = [aws_route_table.dev_private_rt1]

}