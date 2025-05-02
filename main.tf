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

resource "aws_route_table_association" "public_subnet_asso1" {
  subnet_id      = aws_subnet.wordpress-vpc.id
  route_table_id = aws_route_table.second_rt.id
}

# funktioniert nicht 
#resource "aws_route_table_association" "public_subnet_asso2" {
#  gateway_id     = aws_internet_gateway.gw.id
#  route_table_id = aws_route_table.second_rt.id
#}

# Security Group

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow ssh inbound traffic"
  vpc_id      = aws_vpc.wordpress-vpc.id

  ingress {
    description = "allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}

/*
#For creating new key pair for ssh into EC2 machine - check?
# Generate new private key 
resource "tls_private_key" "my_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Generate a key-pair with above key
resource "aws_key_pair" "deployer" {
  key_name   = "task3-key"
  public_key = tls_private_key.my_key.public_key_openssh
}

# Saving Key Pair
resource "null_resource" "save_key_pair"  {
	provisioner "local-exec" {
	    command = "echo  ${tls_private_key.my_key.private_key_pem} > mykey.pem"
  	}
}
*/

#EC2
resource "aws_instance" "wordpress_server" {
  ami                         = "ami-0dd574ef87b79ac6c"
  instance_type               = "t3.nano"
  key_name                    = vockey1 #aws_key_pair.deployer.key_name
  subnet_id                   = aws_subnet.wordpress-vpc.id
  security_groups             = [aws_security_group.allow_ssh.id]
  associate_public_ip_address = true

}