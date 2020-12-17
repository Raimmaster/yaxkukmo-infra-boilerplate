data "aws_ami" "ubuntu_yaxkukmo_vpn" {
  most_recent = true

  filter {
    name   = "name"
    values = ["yaxkukmo-vpn"]
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
resource "aws_security_group" "jumper-sg" {
  name        = "web_app-jumper-${terraform.workspace}-sg"
  description = "Allow inbound traffic and outbound internet traffic"
  vpc_id      = var.vpc

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    description = "SSH"
    cidr_blocks = [var.home_ip]
    self        = true
  }

  ingress {
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = [var.home_ip]
    description = "OpenVPN"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    self        = true
  }

  tags = {
    Name      = "vpn-ssh-outbound-internet"
    Terraform = "true"
  }
}

resource "aws_instance" "jumper_vpn" {
  ami                         = data.aws_ami.ubuntu_yaxkukmo_vpn.id
  instance_type               = "t3.micro"
  subnet_id                   = var.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.jumper-sg.id]
  associate_public_ip_address = true
  key_name                    = "terraform-deploy-key"

  tags = {
    Name        = "web_app-jumper-vpn-${terraform.workspace}"
    Terraform   = "true"
    Environment = terraform.workspace
    Scope       = "${terraform.workspace}-infrastructure"
  }
}