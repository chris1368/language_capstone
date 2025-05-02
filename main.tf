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

  cidr_block = "10.0.0.0/16"

}

# Creating Subnet

resource "aws_subnet" "wordpress-vpc" {
  vpc_id     = aws_vpc.wordpress-vpc.id
  cidr_block = "10.0.1.0/24"
}