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