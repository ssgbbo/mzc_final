
resource "aws_vpc" "dev_vpc" {
  cidr_block           = var.dev_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "dev-lsb-vpc"
  }
}

resource "aws_internet_gateway" "dev_igw" {
  vpc_id = aws_vpc.dev_vpc.id
  tags = {
    Name = "dev-lsb-igw"
  }
}

resource "aws_nat_gateway" "dev_ngw1" {
  allocation_id = aws_eip.dev_nat_eip1.id
  subnet_id     = aws_subnet.dev_public_subnet_1.id

  depends_on    = [aws_subnet.dev_public_subnet_1]

  tags = {
    Name = "dev-lsb-nat-1"
  }
}

resource "aws_eip" "dev_nat_eip1" {
  domain = "vpc"

  tags = {
    Name = "dev-lsb-eip-1"
  }
  depends_on = [aws_subnet.dev_private_subnet_2]
}

resource "aws_subnet" "dev_private_subnet_1" {
  vpc_id            = aws_vpc.dev_vpc.id
  cidr_block        = var.dev_private_subnet_1
  availability_zone = var.dev_availibilty_zone_1
  tags = {
    Name = "dev-lsb-app-subnet-1"
  }
}

resource "aws_subnet" "dev_private_subnet_2" {
  vpc_id            = aws_vpc.dev_vpc.id
  cidr_block        = var.dev_private_subnet_2
  availability_zone = var.dev_availibilty_zone_2
  tags = {
    Name = "dev-lsb-app-subnet-2"
  }
}

resource "aws_subnet" "dev_public_subnet_1" {
  vpc_id                  = aws_vpc.dev_vpc.id
  cidr_block              = var.dev_public_subnet_1
  availability_zone       = var.dev_availibilty_zone_1
  map_public_ip_on_launch = true
  tags = {
    Name = "dev-lsb-public-subnet-1"
  }
}

resource "aws_subnet" "dev_public_subnet_2" {
  vpc_id                  = aws_vpc.dev_vpc.id
  cidr_block              = var.dev_public_subnet_2
  availability_zone       = var.dev_availibilty_zone_2
  map_public_ip_on_launch = true
  tags = {
    Name = "dev-lsb-public-subnet-2"
  }
}

resource "aws_route_table" "dev_public-rt" {
  vpc_id = aws_vpc.dev_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dev_igw.id
  }
  tags = {
    Name = "dev-lsb-public-rt-1"
  }
  depends_on = [aws_nat_gateway.dev_ngw1]
}

resource "aws_route_table_association" "dev_public1" {
  subnet_id      = aws_subnet.dev_public_subnet_1.id
  route_table_id = aws_route_table.dev_public-rt.id
  depends_on     = [aws_route_table.dev_public-rt]
}
resource "aws_route_table_association" "dev_public2" {
  subnet_id      = aws_subnet.dev_public_subnet_2.id
  route_table_id = aws_route_table.dev_public-rt.id
  depends_on     = [aws_route_table.dev_public-rt]
}

resource "aws_route_table" "dev_private_rt1" {
  vpc_id = aws_vpc.dev_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.dev_ngw1.id
  }

  tags = {
    Name = "dev-lsb-private_rt1"
  }
  depends_on = [aws_subnet.dev_private_subnet_1]
}

resource "aws_route_table_association" "dev_association_private_rt1" {
  subnet_id      = aws_subnet.dev_private_subnet_1.id
  route_table_id = aws_route_table.dev_private_rt1.id

  depends_on = [aws_route_table.dev_private_rt1]
}

resource "aws_route_table_association" "dev_association_private-rt2" {
  subnet_id      = aws_subnet.dev_private_subnet_2.id
  route_table_id = aws_route_table.dev_private_rt1.id

  depends_on = [aws_route_table.dev_private_rt1]
}

