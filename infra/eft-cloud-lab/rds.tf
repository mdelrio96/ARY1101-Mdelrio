# Capa de datos RDS MySQL 8.0 en subnets privadas.
# La alta disponibilidad se implementa con una instancia primaria más una
# réplica de lectura enlazada por `replicate_source_db`, replicando el patrón
# del laboratorio EA2. La réplica ofrece redundancia de datos y descarga de
# lecturas sin depender del Multi-AZ nativo, que el entorno de laboratorio
# no habilita de forma consistente.
# La contraseña del admin se genera dentro de Terraform y queda en el tfstate;
# se recupera con `terraform output -raw db_password`.

resource "random_password" "db_master" {
  length  = 16
  special = false
}

resource "aws_db_subnet_group" "main" {
  name       = "${local.prefix}-db-subnets"
  subnet_ids = aws_subnet.private[*].id

  tags = { Name = "${local.prefix}-db-subnets" }
}

# Instancia primaria: recibe escrituras de la aplicación. Mantiene backups
# automáticos (requisito para poder crear la réplica de lectura).
resource "aws_db_instance" "primary" {
  identifier     = "${local.prefix}-db"
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.db_instance_class

  allocated_storage = 20
  storage_type      = "gp2"
  storage_encrypted = true

  db_name  = "tienda_vehiculos"
  username = var.db_username
  password = random_password.db_master.result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false

  multi_az                = false
  backup_retention_period = 7
  backup_window           = "03:00-04:00"

  skip_final_snapshot = true
  apply_immediately   = true

  tags = {
    Name = "${local.prefix}-db"
    Role = "primary"
  }
}

# Réplica de lectura: redundancia de datos y descarga de consultas. Hereda el
# cifrado de la primaria. Al ser réplica en la misma región, adopta el grupo de
# subnets y las características de almacenamiento del origen.
resource "aws_db_instance" "replica" {
  identifier          = "${local.prefix}-db-replica"
  replicate_source_db = aws_db_instance.primary.identifier
  instance_class      = var.db_instance_class

  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false
  skip_final_snapshot    = true

  tags = {
    Name = "${local.prefix}-db-replica"
    Role = "read-replica"
  }

  depends_on = [aws_db_instance.primary]
}
