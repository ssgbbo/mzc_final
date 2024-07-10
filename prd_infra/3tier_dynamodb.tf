#Dynamodb Table
resource "aws_dynamodb_table" "lsb_table" {
  name         = "prd-leavedays"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "leave_id"
  attribute {
    name = "leave_id"
    type = "N"
  }
  tags = {
    Name = "lsb_table"
  }
}

#DynamoDB Endpoint
resource "aws_vpc_endpoint" "dynamodb_Endpoint" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.us-west-1.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private_rt1.id, aws_route_table.private-rt2.id]
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
    Name = "prd-lsb-vpc-db-endpoint"
  }
  depends_on = [aws_route_table.private-rt2]
}