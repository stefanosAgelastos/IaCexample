provider "aws" {
  profile = "default"
  region  = "eu-north-1"
}

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
  default     = 8080
}

resource "aws_security_group" "instance" {
  name = "terraform-example-instance"
  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_configuration" "example" {
  image_id        = "ami-ada823d3"
  instance_type   = "t3.micro"
  security_groups = [aws_security_group.instance.id]
  user_data       = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p "${var.server_port}" &
              EOF
  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.id
  vpc_zone_identifier  = data.aws_subnet_ids.example.ids
  min_size             = 2
  max_size             = 10
  tag {
    key                 = "Name"
    value               = "terraform-asg-example"
    propagate_at_launch = true
  }
}

data "aws_vpc" "selected" {
  default = true
}

data "aws_subnet_ids" "example" {
  vpc_id = "${data.aws_vpc.selected.id}"
}

output "instance_ip_addr" {
  value = data.aws_subnet_ids.example.ids
}

resource "aws_lb" "test" {
  name               = "test-alb-tf"
  internal           = false
  load_balancer_type = "application"
  subnets            = data.aws_subnet_ids.example.ids
}

/* security_groups    = ["${aws_security_group.instance.id}"] */
