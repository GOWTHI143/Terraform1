resource "aws_vpc" "VPC" {
  cidr_block = var.vpc_cidr
  tags = {
    "Name" = var.vpc_name
  }
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.VPC.id
  tags = {
    "Name" = var.igw_name
  }
  depends_on = [
    aws_vpc.VPC
  ]
}

resource "aws_subnet" "SUBNT" {
  vpc_id     = aws_vpc.VPC.id
  cidr_block = var.subnet_cidr
  availability_zone = "us-east-1a"
  tags = {
    "Name" = var.subnet_name
  }
  depends_on = [
    aws_vpc.VPC
  ]
}
resource "aws_route_table" "RT" {
  vpc_id = aws_vpc.VPC.id
  tags = {
    "Name" = var.rt_name
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  depends_on = [
    aws_vpc.VPC
  ]
}
resource "aws_route_table_association" "RT-ASSC" {
  subnet_id      = aws_subnet.SUBNT.id
  route_table_id = aws_route_table.RT.id
  depends_on = [
    aws_internet_gateway.igw
  ]
}
resource "aws_security_group" "sg" {
  name        = var.sg_name
  description = "Allow SSH & HTTP"
  vpc_id      = aws_vpc.VPC.id
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    "Name" = var.sg_name
  }
  depends_on = [
    aws_vpc.VPC
  ]
}
resource "aws_key_pair" "key" {
  key_name   = "ami_key"
  public_key = file("~/.ssh/id_rsa.pub")
}
resource "aws_instance" "AMI" {
  ami                         = var.ami-id
  instance_type               = "t2.micro"
  key_name                    = "ami_key"
  subnet_id                   = aws_subnet.SUBNT.id
  vpc_security_group_ids      = [aws_security_group.sg.id]
  associate_public_ip_address = true
  tags = {
    "Name" = "AMI-Instance"
  }
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/id_rsa")
      host        = aws_instance.AMI.public_ip
    }
    inline = [
      "sudo apt update",
      "sudo apt install nginx -y"
    ]
  }
}
resource "aws_ami_from_instance" "AMI-ec2" {
  name               = "AMI-TASK"
  source_instance_id = aws_instance.AMI.id
  depends_on = [
    aws_instance.AMI
  ]
}
resource "aws_launch_template" "Lau_Tmp" {
  name                   = "Lau_Tmp"
  image_id               = aws_ami_from_instance.AMI-ec2.id
  instance_type          = "t2.micro"
  key_name               = "ami_key"
  placement {
    availability_zone = "us-east-1a"
  }
  network_interfaces {
  associate_public_ip_address = true
  subnet_id = aws_subnet.SUBNT.id
  security_groups = [aws_security_group.sg.id]
  }
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "LT"
    }
  }
}
resource "aws_autoscaling_group" "ASG" {
  name = "ASG-TF"
  launch_template {
    id = aws_launch_template.Lau_Tmp.id
    version = "$Latest"
  }
  availability_zones        = ["us-east-1a"]
  max_size                  = 3
  min_size                  = 1
  health_check_grace_period = 30
  health_check_type         = "ELB"
  desired_capacity          = 1
}
resource "aws_lb_target_group" "For-lb" {
  name     = "Listners-tf"
  target_type = "instance"
  vpc_id = aws_vpc.VPC.id
  port = 80
  protocol = "TCP"
   health_check {
    enabled = true

  }
  depends_on = [
  aws_instance.AMI
  ]
}
resource "aws_s3_bucket" "buck_lb"  {
    bucket = "for-lbtf123"
    acl =  "public-read-write"
    tags = {
            Name        = "My bucket from tf"
            Environment = "Dev1"
    }
}
resource "aws_lb" "LB-TF" {
  name               = "lb-tf"
  internal           = false
  load_balancer_type = "network"
  subnet_mapping {
    subnet_id = aws_subnet.SUBNT.id
  }
  access_logs {
    bucket  = aws_s3_bucket.buck_lb.id
    enabled = true
  }
  tags = {
    Environment = "production"
  }
  depends_on = [
    aws_s3_bucket.buck_lb
  ]
}
resource "aws_lb_listener" "forwading" {
  load_balancer_arn = aws_lb.LB-TF.arn
  port              = 80
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.For-lb.arn
  }
  depends_on = [
    aws_lb.LB-TF
  ]
}