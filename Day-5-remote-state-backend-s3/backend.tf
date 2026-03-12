terraform {
  backend "s3" {
    bucket = "terraform-backend-statefile-2356"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}