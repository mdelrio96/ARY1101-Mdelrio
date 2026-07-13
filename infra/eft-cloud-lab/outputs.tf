output "alb_dns" {
  description = "DNS público del ALB (frontend en :80, API en :3001)"
  value       = aws_lb.main.dns_name
}

output "rds_endpoint" {
  description = "Endpoint de la instancia RDS primaria (escrituras)"
  value       = aws_db_instance.primary.address
}

output "rds_replica_endpoint" {
  description = "Endpoint de la réplica de lectura de RDS"
  value       = aws_db_instance.replica.address
}

output "asg_name" {
  description = "Nombre del Auto Scaling Group"
  value       = aws_autoscaling_group.app.name
}

output "db_password" {
  description = "Contraseña generada del admin de RDS (recuperar con terraform output -raw)"
  value       = random_password.db_master.result
  sensitive   = true
}

output "vpc_id" {
  description = "ID de la VPC"
  value       = aws_vpc.main.id
}
