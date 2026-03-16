### vpc ###
resource "aws_vpc" "test-vpc" {
    cidr_block = "10.0.0.0/16"

    tags = {
      Name = "test-vpc"
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

### secret manager ###
resource "aws_secretsmanager_secret" "rds_secret" {
  name                    = "rds-credentials"
  description             = "RDS MySQL credentials for primary-db"
  recovery_window_in_days = 0

  tags = { 
    Name = "RDS-MySQL-Secret"
     }
}

resource "aws_secretsmanager_secret_version" "rds_secret_version" {
  secret_id = aws_secretsmanager_secret.rds_secret.id
  secret_string = jsonencode({
    username = "admin"
    password = "Cloud123"
  })
}

### RDS SubnetGroup ###
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]

  tags = {
    Name        = "RDS-Subnet-Group"
    Environment = "Development"
    Project     = "Dev"
  }
}

### RDS Security Group ###
resource "aws_security_group" "rds-sg" {
  name   = "rds-sg"
  vpc_id = aws_vpc.test-vpc.id

  ingress {
    description     = "MySQL from Backend EC2s"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
     Name = "RDS-SG"
    }
}

### RDS MySql primary-db ###
resource "aws_db_instance" "mysql" {
  identifier              = "primary-db"
  engine                  = "mysql"
  engine_version          = "8.4.7"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  storage_type            = "gp2"
  db_name                 = "mydb"
  username                = jsondecode(aws_secretsmanager_secret_version.rds_secret_version.secret_string).username
  password                = jsondecode(aws_secretsmanager_secret_version.rds_secret_version.secret_string).password
  db_subnet_group_name    = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.rds-sg.id]
  multi_az                = false
  skip_final_snapshot     = true
  backup_retention_period = 1 # Required for read replicas

  tags = {
     Name = "Primary-Database"
    }
}

### RDS Read Replica ###
resource "aws_db_instance" "read-replica" {
  identifier          = "read-replica"
  instance_class      = "db.t3.micro"
  replicate_source_db = aws_db_instance.mysql.identifier
  publicly_accessible = false
  skip_final_snapshot = true

  tags = { 
    Name = "Read-Replica"
    }
}