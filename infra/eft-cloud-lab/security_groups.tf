# Segmentación por capas (pauta 1.3): internet → SG-ALB → SG-WEB → SG-DB.
# Sin puerto 22: el acceso administrativo a las EC2 es vía SSM.

resource "aws_security_group" "alb" {
  name        = "${local.prefix}-sg-alb"
  description = "Capa balanceador: HTTP publico hacia el ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Frontend HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "API backend (el frontend la consume por :3001 del mismo host)"
    from_port   = 3001
    to_port     = 3001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.prefix}-sg-alb" }
}

resource "aws_security_group" "web" {
  name        = "${local.prefix}-sg-web"
  description = "Capa aplicacion: trafico solo desde el ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Frontend desde ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description     = "Backend desde ALB"
    from_port       = 3001
    to_port         = 3001
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.prefix}-sg-web" }
}

resource "aws_security_group" "db" {
  name        = "${local.prefix}-sg-db"
  description = "Capa datos: MySQL solo desde la capa aplicacion"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL desde EC2"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.prefix}-sg-db" }
}
