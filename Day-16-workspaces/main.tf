resource "aws_instance" "name" {
    ami = "ami-01b14b7ad41e17ba4"
    instance_type = "t2.medium"
    tags = {
        Name = "test-instance"
    }   
  
}

#terraform workspace new dev
#terraform workspace new test
#workspaces mostly not recommended for production use, but can be used for learning and testing purposes. It creates separate state files for each workspace, allowing you to manage different environments (like dev, test, prod) within the same configuration.