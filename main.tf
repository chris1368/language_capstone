terraform {

  required_providers {

    aws = {

      source  = "hashicorp/aws"

      version = "5.97.0"

    }
  }
  }

data "template_file" "init" {

  template = filebase64("userData.sh")

  vars = {

    rds_endpoint     = aws_db_instance.wordpress.address

  }

}

#EC2  first wordpress server
resource "aws_instance" "wordpress" {
  ami                         = "ami-0dd574ef87b79ac6c"
  instance_type               = "t3.nano"
  key_name                    = "vockey1" 
  subnet_id                   = aws_subnet.public1.id
  security_groups             = [aws_security_group.allow_ssh.id]
  associate_public_ip_address = true
  user_data = base64encode(data.template_file.init.rendered)
  tags = {
    Name = "WordPress Server 1"
  }

  depends_on = [aws_db_instance.wordpress]
}

#EC2  second wordpress server
resource "aws_instance" "wordpress2" {
  ami                         = "ami-0dd574ef87b79ac6c"
  instance_type               = "t3.nano"
  key_name                    = "vockey1" 
  subnet_id                   = aws_subnet.public2.id
  security_groups             = [aws_security_group.allow_ssh.id]
  associate_public_ip_address = true
  user_data = base64encode(data.template_file.init.rendered)
  tags = {
    Name = "WordPress Server 2"
  }

  depends_on = [aws_db_instance.wordpress]
}



