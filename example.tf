provider "aws" {
  profile = "default"
  region  = "eu-north-1"
}

// hold server port
variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
  default     = 80
}

// get the default VPC id
data "aws_vpc" "selected" {
  default = true
}

// get ids of all the subnets in default VPC
data "aws_subnet_ids" "example" {
  vpc_id = "${data.aws_vpc.selected.id}"
}

// Security Group for the ALB
resource "aws_security_group" "lb_sg" {
  name = "terraform-example-alb"
  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// ALB
resource "aws_lb" "test" {
  name               = "test-alb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.lb_sg.id}"]
  subnets            = data.aws_subnet_ids.example.ids
}

// ALB Target Group for Autoscalling Group
resource "aws_lb_target_group" "test" {
  name     = "tf-example-lb-tg"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.selected.id
  /*   health_check {
    path    = "/"
    matcher = "200"
  } */
}

// Listener for forwarding to Target Group
resource "aws_lb_listener" "server" {
  load_balancer_arn = "${aws_lb.test.arn}"
  port              = var.server_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.test.arn}"
  }
}

//ASG Attachment
resource "aws_autoscaling_attachment" "asg_attachment_bar" {
  autoscaling_group_name = "${aws_autoscaling_group.example.id}"
  alb_target_group_arn   = "${aws_lb_target_group.test.arn}"
}

// Security Group for the Target Instances
resource "aws_security_group" "instance" {
  name = "terraform-example-instance"
  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// Launch Configuration for the Autoscaling Group
resource "aws_launch_configuration" "example" {
  image_id        = "ami-ada823d3"
  instance_type   = "t3.micro"
  security_groups = [aws_security_group.instance.id]
  user_data       = "${file("install_nginx.sh")}"
  lifecycle {
    create_before_destroy = true
  }
}

// Autoscalling Group
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

/* security_groups    = ["${aws_security_group.instance.id}"] */

// output whatever you need. console.log() 
output "aws_autoscaling_group_target_group_arns" {
  value = aws_autoscaling_group.example.target_group_arns
}
