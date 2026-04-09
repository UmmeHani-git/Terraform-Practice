# data "aws_subnet" "name" {
#     filter {
#         name = "tag:Name"
#         values = ["test-subnet"]
#     }
#data blcok to fetch the subnet details based on the tag value
  

#importing the existing ec2 instance to terraform state file
resource "aws_instance" "name" {
    ami = "ami-0ea87431b78a82070"
    instance_type = "t2.micro"
    #vpc_security_group_ids = ["sg-0c8a9b9e3f1d2a1b2"]
    #subnet_id = data.aws_subnet.name.id
    tags = {
        Name = "test"
    }   
  
}
#importing the existing s3 bucket to terraform state file
resource "aws_s3_bucket" "name" {
    bucket = "tfxdtxwxywxwqx"
}
resource "aws_s3_bucket_versioning" "name" {
    bucket = aws_s3_bucket.name.id
    versioning_configuration {
        status = "Suspended"
    }
  
}