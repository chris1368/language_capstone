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

resource "aws_autoscaling_attachment" "name" {
  autoscaling_group_name = aws_autoscaling_group.autoscale.id
  lb_target_group_arn   = aws_lb_target_group.me_alb_tg.arn
  
}