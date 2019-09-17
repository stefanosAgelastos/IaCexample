provider "aws" {
  profile = "default"
  region  = "eu-north-1"
}

resource "aws_instance" "example" {
  ami           = "ami-1b2fa465"
  instance_type = "t3.micro"

  # Tells Terraform that this EC2 instance must be created only after the
  # S3 bucket has been created.
  depends_on = [aws_s3_bucket.example]
}
