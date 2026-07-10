# RDS MySQL 8.0 en subnets privadas: Multi-AZ, cifrado en reposo y
# backups automáticos con retención de 7 días (pauta 1.3 y 1.5).
# La contraseña del admin se genera dentro de Terraform (patrón del
# laboratorio EA2 del docente) y queda en el tfstate; se recupera con
# `terraform output -raw db_password`.

resource "random_password" "db_master" {
  length  = 16
  special = false
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.app_name}-db-subnets"
  subnet_ids = aws_subnet.private[*].id

  tags = { Name = "${var.app_name}-db-subnets" }
}

resource "aws_db_instance" "main" {
  identifier     = "${var.app_name}-db"
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.db_instance_class

  allocated_storage = 20
  storage_type      = "gp2"
  storage_encrypted = true

  username = var.db_username
  password = random_password.db_master.result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false

  multi_az                = var.db_multi_az
  backup_retention_period = 7
  backup_window           = "03:00-04:00"

  skip_final_snapshot = true
  apply_immediately   = true

  tags = { Name = "${var.app_name}-db" }
}
