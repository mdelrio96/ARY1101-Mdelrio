# VPC 10.X.0.0/16 con dos subnets públicas (ALB + ASG) y dos privadas (RDS),
# cada par en una AZ distinta para alta disponibilidad.

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  vpc_cidr = "10.${var.vpc_octet}.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 2)
  # Prefijo con el identificador del propietario: tienda-vehiculos-mdelrio-*
  prefix = "${var.app_name}-${var.owner}"
}

resource "aws_vpc" "main" {
  cidr_block           = local.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "${local.prefix}-vpc" }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${local.prefix}-igw" }
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.${var.vpc_octet}.${count.index + 1}.0/24"
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true

  tags = { Name = "${local.prefix}-public-${local.azs[count.index]}" }
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.${var.vpc_octet}.${count.index + 11}.0/24"
  availability_zone = local.azs[count.index]

  tags = { Name = "${local.prefix}-private-${local.azs[count.index]}" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = { Name = "${local.prefix}-rt-public" }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
