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
#resource "aws_eip" "eip_wordpress" {
#  instance = aws_instance.wordpress.id
#  domain = "vpc"
#  #vpc      = true
#    tags = {
#    Name = "WordPress Server 1 EIP"
#  }
#}

#elastic ip 2
#resource "aws_eip" "eip_wordpress2" {
#  instance = aws_instance.wordpress2.id
#  domain = "vpc"
#  #vpc      = true
#    tags = {
#    Name = "WordPress Server 2 EIP"
#  }
#}

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

#security group
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.wordpress-vpc.id

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP"
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}

data "template_file" "start_userdata" {
  template = <<-EOF
  #!/bin/bash

  # Update system packages
  sudo yum update -y

  # Install httpd (webserver), start and enable it
  sudo yum install httpd -y
  sudo systemctl start httpd
  sudo systemctl enable httpd

  # Install MariaDB, start and enable it
  sudo yum install mariadb105-server -y
  sudo systemctl start mariadb
  sudo systemctl enable mariadb

  # Automate mysql_secure_installation (not the best solution)
  expect <<'EXP_EOF'
  spawn mysql_secure_installation
  expect "Enter current password for root (enter for none):"
  send "\\n"
  expect "Set root password? [Y/n]"
  send "Y\\n"
  expect "New password:"
  send "root\\n"  # Set your desired root password here
  expect "Re-enter new password:"
  send "root\\n"  # Re-enter the root password
  expect "Remove anonymous users? [Y/n]"
  send "Y\\n"
  expect "Disallow root login remotely? [Y/n]"
  send "Y\\n"
  expect "Remove test database and access to it? [Y/n]"
  send "Y\\n"
  expect "Reload privilege tables now? [Y/n]"
  send "Y\\n"
  expect eof
  EXP_EOF

  # Log in to mariadb and create WordPress database and user
  mysql -u root -proot <<MYSQL_SCRIPT
  CREATE DATABASE wordpress;
  CREATE USER 'wp_user'@'localhost' IDENTIFIED BY 'admin123';  # Replace with actual password
  GRANT ALL PRIVILEGES ON wordpress.* TO 'wp_user'@'localhost';
  FLUSH PRIVILEGES;
  EXIT;
  MYSQL_SCRIPT

  # Install PHP and all necessary modules
  sudo yum install php php-mysqlnd php-fpm php-xml php-mbstring -y
  sudo systemctl restart httpd

# Retrieve RDS endpoint from Terraform output
DBName=${rds_db_name}
DBUser=${rds_username}
DBPassword=${rds_password}
RDS_ENDPOINT=${rds_endpoint}

# Create a temporary file to store the database value
sudo touch db.txt
sudo chmod 777 db.txt
sudo echo "DATABASE $DBName;" >> db.txt
sudo echo "USER $DBUser;" >> db.txt
sudo echo "PASSWORD $DBPassword;" >> db.txt
sudo echo "HOST $RDS_ENDPOINT;" >> db.txt


  # Download and extract WordPress
  wget https://wordpress.org/latest.tar.gz
  tar -xvzf latest.tar.gz

  # Move WordPress files to the Apache web directory
  sudo mv wordpress/* /var/www/html/

  # Set correct ownership and permissions
  sudo chown -R apache:apache /var/www/html/*
  sudo chmod -R 755 /var/www/html/*

  # Create wp-config.php file
  cd /var/www/html
  sudo cp wp-config-sample.php wp-config.php


  echo "Terraform output:"


  # Copy wp-config.php file to wordpress directory
sudo cp ./wp-config-sample.php ./wp-config.php
sudo sed -i "s/'database_name_here'/'$DBName'/g" wp-config.php
sudo sed -i "s/'username_here'/'$DBUser'/g" wp-config.php
sudo sed -i "s/'password_here'/'$DBPassword'/g" wp-config.php
sudo sed -i "s/'localhost'/'$RDS_ENDPOINT'/g" wp-config.php

  # Set permissions for wp-config.php
  sudo chmod 644 wp-config.php

  # Restart Apache to ensure everything is loaded
  sudo systemctl restart httpd

  echo "WordPress installation is complete!" # just print a message
  EOF
}



#EC2  first wordpress server
resource "aws_instance" "wordpress" {
  ami                         = "ami-0dd574ef87b79ac6c"
  instance_type               = "t3.nano"
  key_name                    = "vockey1" #aws_key_pair.deployer.key_name
  subnet_id                   = aws_subnet.public1.id
  security_groups             = [aws_security_group.allow_ssh.id]
  associate_public_ip_address = true
  user_data = "${base64encode(data.template_file.start_userdata.rendered)}"
  tags = {
    Name = "WordPress Server 1"
  }

  depends_on = [aws_db_instance.wordpress]
}

#EC2  second wordpress server
resource "aws_instance" "wordpress2" {
  ami                         = "ami-0dd574ef87b79ac6c"
  instance_type               = "t3.nano"
  key_name                    = "vockey1" #aws_key_pair.deployer.key_name
  subnet_id                   = aws_subnet.public2.id
  security_groups             = [aws_security_group.allow_ssh.id]
  associate_public_ip_address = true
  user_data = "${base64encode(data.template_file.start_userdata.rendered)}"
  tags = {
    Name = "WordPress Server 2"
  }

  depends_on = [aws_db_instance.wordpress]
}


#Load balancer
resource "aws_lb" "me_lb" {
  name               = "me-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_ssh.id]
  subnets            = [aws_subnet.public1.id, aws_subnet.public2.id]
  depends_on         = [aws_internet_gateway.igw]
}

resource "aws_lb_target_group" "me_alb_tg" {
  name     = "sh-tf-lb-alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.wordpress-vpc.id
}

resource "aws_lb_listener" "me_front_end" {
  load_balancer_arn = aws_lb.me_lb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.me_alb_tg.arn
  }
}

# Attach EC2 instances to target group
resource "aws_lb_target_group_attachment" "wordpress_1" {
  target_group_arn = aws_lb_target_group.me_alb_tg.arn
  target_id        = aws_instance.wordpress.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "wordpress_2" {
  target_group_arn = aws_lb_target_group.me_alb_tg.arn
  target_id        = aws_instance.wordpress2.id
  port             = 80
}

#######




# ASG with Launch template
resource "aws_launch_template" "me_ec2_launch_templ" {
  name_prefix   = "me_ec2_launch_templ"
  image_id      = "ami-0dd574ef87b79ac6c" # To note: AMI is specific for each region
  instance_type = "t3.nano"
  user_data     =  "${base64encode(data.template_file.start_userdata.rendered)}"

    network_interfaces {
    associate_public_ip_address = true
    #subnet_id                   = [aws_security_group.allow_ssh.id]
    security_groups             = [aws_security_group.allow_ssh.id]
  }
}

resource "aws_autoscaling_group" "autoscale" {
  name                  = "test-autoscaling-group"  
  #availability_zones    = ["eu-north-1"]
  desired_capacity      = 2
  max_size              = 3
  min_size              = 2
  health_check_type     = "EC2"
  termination_policies  = ["OldestInstance"]
  
# Connect to the target group
  target_group_arns = [aws_lb_target_group.me_alb_tg.arn]

  vpc_zone_identifier   =  [# Creating EC2 instances in private subnet
    aws_subnet.public2.id
  ]

  launch_template {
    id      = aws_launch_template.me_ec2_launch_templ.id
    version = "$Latest"
  }
}


########


resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group-new" # <-- change this name
  subnet_ids = [aws_subnet.private1.id, aws_subnet.private2.id]
}
#RDS INSTANCE
resource "aws_db_instance" "wordpress" {
  engine                    = "mysql"
  engine_version            = "5.7"
  skip_final_snapshot       = true
  final_snapshot_identifier = "my-final-snapshot"
  instance_class            = "db.t3.micro"
  allocated_storage         = 20
  identifier                = "my-rds-instance"
  db_name                   = "wordpress_db"
  username                  = "test"
  password                  = "test123$"
  db_subnet_group_name      = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids    = [aws_security_group.rds_security_group.id]

  tags = {
    Name = "RDS Instance"
  }
}


# Variables for RDS DB instance

variable "rds_username" {
  description = "The username for the RDS instance"
}
variable "rds_password" {
  description = "The password for the RDS instance"
  sensitive   = true
}
variable "rds_db_name" {
  description = "The name of the database"
  default     = "wordpressDb"
}



# RDS security group
resource "aws_security_group" "rds_security_group" {
  name        = "rds-security-group"
  description = "Security group for RDS instance"
  vpc_id      = aws_vpc.wordpress-vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.100.0.0/16"]
    #security_groups = [aws_security_group.allow_ssh.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "RDS Security Group"
  }
}