provider "aws" {
  region = "eu-east-1"
}

resource "aws_default_vpc" "default" {} # This need to be added since AWS Provider v4.29+ to get VPC id

data "aws_availability_zones" "available" {}
data "aws_ami" "latest_vm_linux" {
  owners      = ["Alex"]
  most_recent = true
  filter {
    name   = "name"
  }
}

#--------------------------------------------------------------



resource "aws_launch_configuration" "frontend" {
  //  name            = "frontendServer-Highly-Available-LC"
  name_prefix     = "frontendServer-Highly-Available-LC-"
  image_id        = data.aws_ami.latest_vm_linux.id
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.frontend.id]
  #user_data       = file("user_data.sh")

  lifecycle {
    create_before_destroy = true
  }
}



resource "aws_autoscaling_group" "frontend" {
  name                 = "ASG-${aws_launch_configuration.frontend.name}"
  launch_configuration = aws_launch_configuration.frontend.name
  min_size             = 2
  max_size             = 2
  min_elb_capacity     = 2
  health_check_type    = "ELB"
  vpc_zone_identifier  = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]
  load_balancers       = [aws_elb.frontend.name]

  dynamic "tag" {
    for_each = {
      Name   = "frontendServer in ASG"
      Owner  = "Oleksandr Pavliuk"
      TAGKEY = "TAGVALUE"
    }
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}



  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 10
  }
  tags = {
    Name = "frontendServer-Highly-Available-ELB"
  }
}


resource "aws_default_subnet" "default_az1" {
  availability_zone = data.aws_availability_zones.available.names[0]
}

resource "aws_default_subnet" "default_az2" {
  availability_zone = data.aws_availability_zones.available.names[1]
}

