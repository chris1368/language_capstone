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
  
}