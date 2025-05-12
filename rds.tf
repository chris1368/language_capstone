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