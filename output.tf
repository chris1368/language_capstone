output "instance_public_ip" {

  description = "Public IP address of the EC2 instance"

  value       = aws_instance.wordpress.public_ip

}

output "instance_public_ip2" {

  description = "Public IP address of the EC2 instance"

  value       = aws_instance.wordpress2.public_ip

}


output "db_address" {

  value       = aws_db_instance.wordpress.address

  description = "Connect to the database at this endpoint"

}

output "db_port" {

  value       = aws_db_instance.wordpress.port

  description = "The port the database is listening on"

}




