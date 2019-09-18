provider "aws" {
  profile = "default"
  region  = "eu-north-1"
}

// hold server port
variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
  default     = 8080
}

// get the default VPC id
data "aws_vpc" "selected" {
  default = true
}

// get ids of all the subnets in default VPC
data "aws_subnet_ids" "example" {
  vpc_id = "${data.aws_vpc.selected.id}"
}

// ALB
resource "aws_lb" "test" {
  name               = "test-alb-tf"
  internal           = false
  load_balancer_type = "application"
  subnets            = data.aws_subnet_ids.example.ids
}

// Target Group for Autoscalling Group
resource "aws_lb_target_group" "test" {
  name     = "tf-example-lb-tg"
  port     = 8080
  protocol = "TCP"
  vpc_id   = data.aws_vpc.selected.id
  /*   health_check {
    path    = "/"
    matcher = "200"
  } */
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
  target_group_arns    = aws_lb_target_group.test.id
  min_size             = 2
  max_size             = 10
  tag {
    key                 = "Name"
    value               = "terraform-asg-example"
    propagate_at_launch = true
  }
}

/* security_groups    = ["${aws_security_group.instance.id}"] */

// output whatever you need. console.log() 
output "instance_ip_addr" {
  value = aws_lb_target_group.test.id
}