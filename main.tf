terraform {

  required_providers {

    aws = {

      source  = "hashicorp/aws"

      version = "5.94.1"

    }
  }
  }
data "template_file" "start_userdata" {
  template = <<-EOF
  #!/bin/bash

  # Update system packages
  sudo yum update -y

  # Install Apache (httpd)
  sudo yum install httpd -y
  sudo systemctl start httpd
  sudo systemctl enable httpd

  # Install PHP and required extensions
  sudo amazon-linux-extras enable php7.4
  sudo yum clean metadata
  sudo yum install php php-mysqlnd php-fpm php-xml php-mbstring wget unzip -y

  # Restart Apache
  sudo systemctl restart httpd

  # Download and extract WordPress
  wget https://wordpress.org/latest.tar.gz
  tar -xzf latest.tar.gz

  # Move WordPress files to web directory
  sudo mv wordpress/* /var/www/html/

  # Set permissions
  sudo chown -R apache:apache /var/www/html/
  sudo chmod -R 755 /var/www/html/

  # Configure wp-config.php
  cd /var/www/html
  sudo cp wp-config-sample.php wp-config.php

  # Set database credentials
  sudo sed -i "s/database_name_here/wordpress_db/" wp-config.php
  sudo sed -i "s/username_here/test/" wp-config.php
  sudo sed -i "s/password_here/test123$/" wp-config.php
  sudo sed -i "s/localhost/${rds_endpoint}/" wp-config.php

  sudo chmod 644 wp-config.php

  # Final restart
  sudo systemctl restart httpd

  echo "WordPress setup with RDS completed!"
  EOF

  vars = {
    rds_endpoint = aws_db_instance.wordpress.address
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
  user_data = base64encode(data.template_file.start_userdata.rendered)
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
  user_data = base64encode(data.template_file.start_userdata.rendered)
  tags = {
    Name = "WordPress Server 2"
  }

  depends_on = [aws_db_instance.wordpress]
}



