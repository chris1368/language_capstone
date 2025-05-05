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