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