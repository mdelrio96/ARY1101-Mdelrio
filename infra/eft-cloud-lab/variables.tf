variable "aws_region" {
  description = "Región AWS"
  type        = string
  default     = "us-east-1"
}

variable "vpc_octet" {
  description = "Octeto X en 10.X.0.0/16"
  type        = number
  default     = 50
}

variable "instance_type" {
  description = "Tipo de instancia EC2 del ASG (Learner Lab: nano a large)"
  type        = string
  default     = "t3.micro"
}

variable "asg_min_size" {
  description = "Tamaño mínimo del ASG (pauta EFT: 2)"
  type        = number
  default     = 2
}

variable "asg_desired_capacity" {
  description = "Capacidad deseada del ASG (pauta EFT: 2)"
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "Tamaño máximo del ASG (pauta EFT: 4)"
  type        = number
  default     = 4
}

variable "db_instance_class" {
  description = "Clase de instancia RDS (Learner Lab: hasta medium)"
  type        = string
  default     = "db.t3.micro"
}

variable "db_multi_az" {
  description = "Habilita Multi-AZ en RDS (pauta EFT); desactivable si el Learner Lab lo rechaza"
  type        = bool
  default     = true
}

variable "db_username" {
  description = "Usuario administrador de RDS"
  type        = string
  default     = "admin"
}

variable "dockerhub_username" {
  description = "Usuario de Docker Hub dueño de las imágenes tienda-vehiculos-*"
  type        = string
}

variable "image_tag" {
  description = "Tag de las imágenes a desplegar"
  type        = string
  default     = "latest"
}

variable "app_name" {
  description = "Prefijo de nombres de recursos"
  type        = string
  default     = "tienda-vehiculos"
}

variable "owner" {
  description = "Identificador del propietario, incluido en el nombre de cada recurso"
  type        = string
  default     = "mdelrio"
}
