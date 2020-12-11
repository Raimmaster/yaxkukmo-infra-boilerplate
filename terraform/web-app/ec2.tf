data "aws_ami" "ubuntu_yaxkukmo" {
  most_recent = true

  filter {
    name   = "name"
    values = ["yaxkukmo-web-app-v1"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["self"]
}

data "aws_acm_certificate" "web_app_domain" {
  domain   = var.domain
  statuses = ["ISSUED"]
}

resource "aws_security_group" "allow_internet_access_sg" {
  name        = "allow_internet_access_sg"
  description = "Allow HTTP and HTTPS inbound traffic and SSH from jumper VPN IP"

  vpc_id = var.vpc

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"

    cidr_blocks = ["${var.jumper_ip}/32"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
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
    Name      = "web-app-http-https-and-vpn-ssh"
    Terraform = "true"

  }
}

resource "aws_key_pair" "instance_creation_key" {
  key_name   = "terraform-deploy-key"
  public_key = var.public_key

  tags = {
    Name      = "terraform-deploy-key"
    Terraform = "true"
    Project   = "yaxkukmo"
  }
}

resource "aws_lb" "web_app_lb" {
  name               = "yaxkukmo-web-app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_internet_access_sg.id]
  subnets            = var.public_subnets

  enable_deletion_protection = false

  tags = {
    Name      = "yaxkukmo-web-app-lb"
    Terraform = "true"
  }
}

resource "aws_lb_target_group" "web_app_tg" {
  health_check {
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "200-299"
  }

  name        = "yaxkukmo-web-app-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc
  target_type = "instance"
}

resource "aws_lb_listener" "web_app_listener" {
  load_balancer_arn = aws_lb.web_app_lb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.web_app_domain.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_app_tg.arn
  }
}

resource "aws_lb_listener" "web_app_listener_redirect_http_to_https" {
  load_balancer_arn = aws_lb.web_app_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "redirect"
    target_group_arn = aws_lb_target_group.web_app_tg.arn
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"

    }
  }
}

module "autoscaler" {

  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 3.0"

  name              = "yaxkukmo-autoscaler"
  enable_monitoring = true

  lc_name = "yaxkukmo-lc"

  image_id                     = data.aws_ami.ubuntu_yaxkukmo.id
  instance_type                = "t3.micro"
  security_groups              = [aws_security_group.allow_internet_access_sg.id]
  target_group_arns            = [aws_lb_target_group.web_app_tg.arn]
  associate_public_ip_address  = false
  recreate_asg_when_lc_changes = true
  force_delete                 = false
  key_name                     = aws_key_pair.instance_creation_key.key_name
  root_block_device = [
    {
      volume_size = "8"
      volume_type = "gp2"
      encrypted   = "true"
    },
  ]

  asg_name            = "yaxkukmo-asg"
  vpc_zone_identifier = var.private_subnets
  health_check_type   = "EC2"

  health_check_grace_period = 300
  min_size                  = 1
  max_size                  = 2
  desired_capacity          = 2
  min_elb_capacity          = 1
  wait_for_capacity_timeout = 0

  tags = [
    {
      key                 = "Environment"
      value               = terraform.workspace
      propagate_at_launch = true
    },
    {
      key                 = "Project"
      value               = "yaxkukmo"
      propagate_at_launch = true
    },
  ]
}