module "rds_mysql" {
  source = "../Day-10-rds-with-variables"

  # VPC
  vpc_cidr                = "10.0.0.0/16"
  private_subnet_1_cidr   = "10.0.1.0/24"
  private_subnet_2_cidr   = "10.0.2.0/24"
  az1                     = "us-east-1a"
  az2                     = "us-east-1b"
  allowed_cidr            = ["0.0.0.0/0"]

  # RDS
  db_identifier     = "my-rds-db"
  allocated_storage = 20
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"

  db_name  = "mydb"
  username = "admin"
  password = "Admin1234"
}