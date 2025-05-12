 # Creating VPC

resource "aws_vpc" "wordpress-vpc" {

  cidr_block = "10.100.0.0/16"

   tags = {
    Name = "wordpress_vpc"
  }

}

# Creating Public Subnets

resource "aws_subnet" "public1" {
  vpc_id     = aws_vpc.wordpress-vpc.id
  cidr_block = "10.100.1.0/24"
  availability_zone = "eu-north-1a"

   tags = {
    Name = "Public Subnet 1"
  }
}

resource "aws_subnet" "public2" {
  vpc_id     = aws_vpc.wordpress-vpc.id
  cidr_block = "10.100.2.0/24"
  availability_zone = "eu-north-1b"

  tags = {
    Name = "Public Subnet 2"
  }
}

#private subnets

resource "aws_subnet" "private1" {
  vpc_id     = aws_vpc.wordpress-vpc.id
  cidr_block = "10.100.3.0/24"
  availability_zone = "eu-north-1a"

  tags = {
    Name = "Private Subnet 1"
  }
}
resource "aws_subnet" "private2" {
  vpc_id     = aws_vpc.wordpress-vpc.id
  cidr_block = "10.100.4.0/24"
  availability_zone = "eu-north-1b"

  tags = {
    Name = "Private Subnet 2"
  }
}

#internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.wordpress-vpc.id

  tags = {
    Name = "igw_wordpress"
  }
}


#elastic ip
resource "aws_eip" "eip" {
  domain = "vpc"
}

#nat gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public1.id

  tags = {
    Name = "upgrad-nat"
  }
}

#public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.wordpress-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

#private route table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.wordpress-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "private-rt"
  }
}


#route table association
resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "private1" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.private.id
}
resource "aws_route_table_association" "private2" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.private.id
}