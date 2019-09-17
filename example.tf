provider "aws" {
  profile = "default"
  region  = "eu-north-1"
}

# New resource for the S3 bucket our application will use.
resource "aws_s3_bucket" "example" {
  # NOTE: S3 bucket names must be unique across _all_ AWS accounts, so
  # this name must be changed before applying this example to avoid naming
  # conflicts.
  bucket = "terraform-getting-started-guide"
  acl    = "private"
}

resource "aws_instance" "example" {
  ami           = "ami-1b2fa465"
  instance_type = "t3.micro"

  # Tells Terraform that this EC2 instance must be created only after the
  # S3 bucket has been created.
  depends_on = [aws_s3_bucket.example]
}

resource "aws_eip" "ip" {
  vpc      = true
  instance = aws_instance.example.id
}

resource "aws_instance" "another" {
  ami           = "ami-1b2fa465"
  instance_type = "t3.micro"
}