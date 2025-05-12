  #!/bin/bash
    echo "start_user_data"
  # Update system packages
   yum update -y

  # Install Apache (httpd)
   yum install httpd -y
   systemctl start httpd
   systemctl enable httpd

  # Install PHP and required extensions
   amazon-linux-extras enable php7.4
   yum clean metadata
   yum install php php-mysqlnd php-fpm php-xml php-mbstring wget unzip -y

  # Restart Apache
   systemctl restart httpd

  # Download and extract WordPress
  wget https://wordpress.org/latest.tar.gz
  tar -xzf latest.tar.gz

  # Move WordPress files to web directory
   mv wordpress/* /var/www/html/

  # Set permissions
   chown -R apache:apache /var/www/html/
   chmod -R 755 /var/www/html/

  # Configure wp-config.php
   cd /var/www/html
   cp wp-config-sample.php wp-config.php

  # Set database credentials
   sed -i "s/database_name_here/wordpress_db/" wp-config.php
   sed -i "s/username_here/test/" wp-config.php
   sed -i "s/password_here/test123$/" wp-config.php
   sed -i "s/localhost/${rds_endpoint}/" wp-config.php

   chmod 644 wp-config.php

  # Final restart
   systemctl restart httpd

  echo "WordPress setup with RDS completed!"
  
