### vpc ###
resource "aws_vpc" "test-vpc" {
    cidr_block = "10.0.0.0/16"

    tags = {
      Name = "Test-vpc"
    }

}
### Subnets ###
resource "aws_subnet" "subnet1" {
    vpc_id = aws_vpc.test-vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1a"

    tags = {
      Name = "Subnet-1a"
    }
  
}

resource "aws_subnet" "subnet2" {
    vpc_id = aws_vpc.test-vpc.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "us-east-1b"

    tags = {
      Name = "Subnet-2b"
    }
  
}

### subnetGroup for RDS ###
resource "aws_db_subnet_group" "db-sub" {
    name = "rds-subnet-group"

    subnet_ids = [ 
        aws_subnet.subnet1.id,
        aws_subnet.subnet2.id
     ]

     tags = {
       Name = "my-db-sub"
     }
  
}

### RDS Instance ###
resource "aws_db_instance" "main" {
    identifier = "rds-instance"
    allocated_storage = 20
    engine = "mysql"
    engine_version = "8.4"
    instance_class = "db.t3.micro"

    db_name = "myDatabase"
    username = "admin"
    password = "cloud123"
    #here you can use secret manager 
    #manage_master_user_password = true #rds and secret manager manage this password
    db_subnet_group_name = aws_db_subnet_group.db-sub.name
    parameter_group_name = "default.mysql8.4"

    backup_retention_period = 1
    backup_window = "18:00-19:00"
    maintenance_window = "sun:19:00-sun:20:00"

    deletion_protection = true
    skip_final_snapshot = true

    depends_on = [ aws_db_subnet_group.db-sub ]
    vpc_security_group_ids = [ aws_security_group.rds_sg.id ]
}

## RDS Read Replica ##

resource "aws_db_instance" "replica" {
  identifier             = "rdsdb-replica"
   replicate_source_db = aws_db_instance.main.arn
  instance_class         = "db.t3.micro"
  db_subnet_group_name = aws_db_subnet_group.db-sub.name
  publicly_accessible    = false
  auto_minor_version_upgrade = true

  depends_on = [aws_db_instance.main]
}
# iam ploicy for monitoring RDS instance
resource "aws_iam_role" "rds_monitoring" {
  name = "rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "monitoring.rds.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring_attach" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
} 
# this is security group for RDS instance

resource "aws_security_group" "rds_sg" {
  name   = "rds-security-group"
  vpc_id = aws_vpc.test-vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}