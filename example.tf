provider "aws" {
  profile = "default"
  region  = "eu-north-1"
}

resource "aws_instance" "example" {
  ami           = "ami-1b2fa465"
  instance_type = "t3.micro"
}
