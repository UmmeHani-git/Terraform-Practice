# ============================================================
# TERRAFORM LIFECYCLE RULES - COMPLETE EXAMPLE
# ============================================================

provider "aws" {
  region = "us-east-1"
}

locals {
  env    = "test"
  prefix = "lifecycle-demo"
}

# ============================================================
# RULE 1: create_before_destroy
# Creates new resource BEFORE destroying the old one
# Use case: Zero downtime replacement for web servers
# ============================================================
resource "aws_instance" "web" {
  ami           = "ami-0c3389a4fa5bddaad"
  instance_type = "t2.micro"

  tags = {
    Name = "${local.prefix}-web"
  }

  lifecycle {
    create_before_destroy = true
    # Without this: OLD deleted → NEW created (downtime gap)
    # With this:    NEW created → OLD deleted (no downtime)
  }
}

# ============================================================
# RULE 2: prevent_destroy
# Blocks 'terraform destroy' from deleting this resource
# Use case: Protect critical production databases
# ============================================================
resource "aws_s3_bucket" "critical_data" {
  bucket = "${local.prefix}-critical-bucket"

  tags = {
    Name = "${local.prefix}-critical-bucket"
  }

  lifecycle {
    prevent_destroy = true
    # Running 'terraform destroy' will throw:
    # Error: Instance cannot be destroyed
    # Remove this rule first before destroying
  }
}

# ============================================================
# RULE 3: ignore_changes
# Ignores specific attribute changes made outside Terraform
# Use case: Tags or fields updated manually in AWS Console
# ============================================================
resource "aws_instance" "app" {
  ami           = "ami-0c3389a4fa5bddaad"
  instance_type = "t2.micro"

  tags = {
    Name        = "${local.prefix}-app"
    LastUpdated = "2024-01-01"   # May be changed manually in console
    Owner       = "team-a"       # May be changed manually in console
  }

  lifecycle {
    ignore_changes = [
      tags["LastUpdated"],  # Ignore this specific tag
      tags["Owner"],        # Ignore this specific tag
      ami,                  # Ignore AMI changes from console
      instance_type,        # Ignore instance type changes from console
    ]
    # terraform plan will show NO changes even if above fields
    # are modified directly in the AWS Console
  }
}

# ============================================================
# RULE 4: replace_triggered_by
# Forces resource replacement when a dependent resource changes
# Use case: EC2 must be replaced when its Security Group changes
# ============================================================

# --- Security Group (changing this will trigger EC2 replacement) ---
resource "aws_security_group" "backend_sg" {
  name        = "${local.prefix}-backend-sg"
  description = "Backend security group"

  ingress {
    from_port   = 80
    to_port     = 80
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

resource "aws_instance" "backend" {
  ami                    = "ami-0c3389a4fa5bddaad"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.backend_sg.id]

  tags = {
    Name = "${local.prefix}-backend"
  }

  lifecycle {
    replace_triggered_by = [
      aws_security_group.backend_sg  # If SG is replaced → EC2 is replaced too
    ]
    # Without this: SG changes → EC2 just updates in-place
    # With this:    SG changes → EC2 is fully replaced (fresh instance)
  }
}

# ============================================================
# RULE 5: ignore_changes = all
# Ignores ALL changes to this resource after initial creation
# Use case: One-time bootstrap resources, never touched again
# ============================================================
resource "aws_instance" "bootstrap" {
  ami           = "ami-0c3389a4fa5bddaad"
  instance_type = "t2.micro"

  tags = {
    Name = "${local.prefix}-bootstrap"
  }

  lifecycle {
    ignore_changes = all
    # Terraform will NEVER modify this resource after creation
    # Any change in config or console → completely ignored
  }
}

# ============================================================
# RULE 6: ALL RULES COMBINED
# Real-world production-grade resource
# ============================================================
resource "aws_instance" "production" {
  ami                    = "ami-0c3389a4fa5bddaad"
  instance_type          = "t3.medium"
  vpc_security_group_ids = [aws_security_group.backend_sg.id]

  tags = {
    Name        = "${local.prefix}-production"
    LastUpdated = "2024-01-01"
    ManagedBy   = "terraform"
  }

  lifecycle {
    # 1. Create new before destroying old (zero downtime)
    create_before_destroy = true

    # 2. Never allow accidental destroy
    prevent_destroy = true

    # 3. Ignore manual changes from AWS Console
    ignore_changes = [
      tags["LastUpdated"],
      ami,
    ]

    # 4. Replace this instance if SG is replaced
    replace_triggered_by = [
      aws_security_group.backend_sg
    ]
  }
}

# ============================================================
# OUTPUTS
# ============================================================
output "web_instance_id" {
  value       = aws_instance.web.id
  description = "Web instance (create_before_destroy)"
}

output "app_instance_id" {
  value       = aws_instance.app.id
  description = "App instance (ignore_changes)"
}

output "backend_instance_id" {
  value       = aws_instance.backend.id
  description = "Backend instance (replace_triggered_by)"
}

output "bootstrap_instance_id" {
  value       = aws_instance.bootstrap.id
  description = "Bootstrap instance (ignore_changes = all)"
}

output "s3_bucket_name" {
  value       = aws_s3_bucket.critical_data.bucket
  description = "S3 bucket (prevent_destroy)"
}