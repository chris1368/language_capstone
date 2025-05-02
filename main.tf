terraform {

  required_providers {

    aws = {

      source  = "hashicorp/aws"

      version = "5.94.1"

    }
  }
  }

  # Creating VPC

resource "aws_vpc" "wordpress-vpc" {

  cidr_block = "10.0.0.0/18"

   tags = {
    Name = "wordpress_vpc"
  }

}



# Creating Subnet

resource "aws_subnet" "wordpress-vpc" {
  vpc_id     = aws_vpc.wordpress-vpc.id
  cidr_block = "10.0.1.0/24"

   tags = {
    Name = "Public Subnet"
  }
}

# Internet Gateway

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.wordpress-vpc.id

  tags = {
    Name = "internet gateway wordpress"
  }
}

# Route Table

resource "aws_route_table" "second_rt" {
 vpc_id = aws_vpc.wordpress-vpc.id
 
 route {
   cidr_block = "0.0.0.0/0"
   gateway_id = aws_internet_gateway.gw.id
 }
 
 tags = {
   Name = "2nd Route Table"
 }
}

# Associate Public Subnets with the Second Route Table

resource "aws_route_table_association" "public_subnet_asso" {
  gateway_id     = aws_internet_gateway.gw.id
  route_table_id = aws_route_table.second_rt.id
}