# This file describes the vpc, internet gateway, nat gateway and route tables

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "prd-lsb-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "prd-lsb-igw"
  }
}

resource "aws_nat_gateway" "ngw1" {
  allocation_id = aws_eip.nat-eip1.id
  subnet_id     = aws_subnet.public_subnet_1.id

  depends_on    = [aws_subnet.public_subnet_1]

  tags = {
    Name = "prd-lsb-nat-1"
  }
}

resource "aws_nat_gateway" "ngw2" {
  allocation_id = aws_eip.nat-eip2.id
  subnet_id     = aws_subnet.public_subnet_2.id

  depends_on    = [aws_subnet.public_subnet_2]

  tags = {
    Name = "prd-lsb-nat-2"
  }
}

resource "aws_eip" "nat-eip1" {
  domain = "vpc"

  tags = {
    Name = "prd-lsb-eip-1"
  }
  depends_on = [aws_subnet.private_subnet_1]
}
resource "aws_eip" "nat-eip2" {
  domain = "vpc"

  tags = {
    Name = "prd-lsb-eip-2"
  }
  depends_on = [aws_subnet.private_subnet_2]
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private_subnet_1
  availability_zone = var.availibilty_zone_1
  tags = {
    Name = "prd-lsb-app-subnet-1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private_subnet_2
  availability_zone = var.availibilty_zone_2
  tags = {
    Name = "prd-lsb-app-subnet-2"
  }
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public_subnet_1
  availability_zone       = var.availibilty_zone_1
  map_public_ip_on_launch = true
  tags = {
    Name = "prd-lsb-public-subnet-1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public_subnet_2
  availability_zone       = var.availibilty_zone_2
  map_public_ip_on_launch = true
  tags = {
    Name = "prd-lsb-public-subnet-2"
  }
}

resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "prd-lsb-public-rt-1"
  }
  depends_on = [aws_nat_gateway.ngw2]
}

resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public-rt.id
  depends_on     = [aws_route_table.public-rt]
}
resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public-rt.id
  depends_on     = [aws_route_table.public-rt]
}

resource "aws_route_table" "private_rt1" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ngw1.id
  }

  tags = {
    Name = "prd-lsb-private_rt1"
  }
  depends_on = [aws_subnet.private_subnet_2]
}


resource "aws_route_table_association" "private_rt1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_rt1.id

  depends_on = [aws_route_table.private_rt1]
}

resource "aws_route_table" "private-rt2" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ngw2.id
  }

  tags = {
    Name = "prd-lsb-private-rt2"
  }
  depends_on = [aws_route_table.private_rt1]
}

resource "aws_route_table_association" "private-rt2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private-rt2.id
  depends_on     = [aws_route_table.private-rt2]
}