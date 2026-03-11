provider "aws" {
  alias   = "devenv"
  region  = "ap-south-1"
  profile = "dev"
}

provider "aws" {
  alias   = "testenv"
  region  = "us-east-1"
  profile = "test"
}


