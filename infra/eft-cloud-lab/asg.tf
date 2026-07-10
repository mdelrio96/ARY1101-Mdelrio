# Launch Template + Auto Scaling Group (mín 2 / deseado 2 / máx 4, pauta 1.3).
# Cada instancia se auto-configura por user-data: instala Docker, descarga las
# imágenes desde Docker Hub y levanta frontend + backend con Docker Compose.
# Acceso administrativo vía SSM con LabInstanceProfile (sin SSH).

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_launch_template" "app" {
  name_prefix   = "${var.app_name}-lt-"
  image_id      = data.aws_ami.al2023.id
  instance_type = var.instance_type

  iam_instance_profile {
    name = "LabInstanceProfile"
  }

  vpc_security_group_ids = [aws_security_group.web.id]

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 20
      volume_type = "gp3"
      encrypted   = true
    }
  }

  user_data = base64encode(templatefile("${path.module}/config/user_data.sh.tpl", {
    dockerhub_username = var.dockerhub_username
    image_tag          = var.image_tag
    db_host            = aws_db_instance.main.address
    db_user            = var.db_username
    db_password        = random_password.db_master.result
    db_name            = "tienda_vehiculos"
  }))

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${var.app_name}-asg-node" }
  }
}

resource "aws_autoscaling_group" "app" {
  name                = "${var.app_name}-asg"
  min_size            = var.asg_min_size
  desired_capacity    = var.asg_desired_capacity
  max_size            = var.asg_max_size
  vpc_zone_identifier = aws_subnet.public[*].id

  target_group_arns = [
    aws_lb_target_group.frontend.arn,
    aws_lb_target_group.backend.arn,
  ]

  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.app_name}-asg-node"
    propagate_at_launch = true
  }
}

# Escalamiento por CPU al 70% (coherente con las alarmas de la pauta 1.4).
resource "aws_autoscaling_policy" "cpu_target" {
  name                   = "${var.app_name}-cpu-70"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70
  }
}
