provider "aws" {
  profile    = "default"
  region     = "eu-north-1"
}

resource "aws_instance" "example" {
  ami           = "ami-ada823d3"
  instance_type = "t3.micro"
}