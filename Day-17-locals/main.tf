locals {
  region        = "us-east-1"
  instance_type = "t2.micro"
  ami_id= "ami-0ea87431b78a82070"
}

resource "aws_instance" "name" {
  ami = local.ami_id
  instance_type = local.instance_type
  region = local.region
}