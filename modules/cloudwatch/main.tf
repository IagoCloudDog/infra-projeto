resource "aws_cloudwatch_dashboard" "monitoring_dashboard" {
  count          = var.create_dashboard ? 1 : 0
  dashboard_name = "${var.customer_name}-dashboard-${var.environment_name}"
  dashboard_body = jsonencode({
    widgets = concat(
      // Cabeçalho ALB (incluso se existir pelo menos 1 ALB)
      length(data.aws_lb.application_lb) > 0 ? [
        {
          type   = "text"
          x      = 0
          y      = 0
          width  = 24
          height = 1
          properties = {
            markdown   = "# Application Load Balancer Metrics\n\n"
            background = "transparent"
          }
        }
      ] : [],
      // Widgets ALB
      local.application_lb_widgets,

      // Cabeçalho NLB (incluso se existir pelo menos 1 NLB)
      length(data.aws_lb.network_lb) > 0 ? [
        {
          type   = "text"
          x      = 0
          y      = local.nlb_header_y
          width  = 24
          height = 1
          properties = {
            markdown   = "# Network Load Balancer Metrics\n\n"
            background = "transparent"
          }
        }
      ] : [],
      // Widgets NLB
      local.network_lb_widgets,

      // Cabeçalho EC2 (incluso se existir pelo menos 1 instância EC2)
      length(data.aws_instances.existing.ids) > 0 ? [
        {
          type   = "text"
          x      = 0
          y      = local.ec2_header_y
          width  = 24
          height = 1
          properties = {
            markdown   = "# EC2 Metrics\n\n"
            background = "transparent"
          }
        }
      ] : [],
      // Widgets EC2
      local.ec2_widgets,

      // Cabeçalho RDS (incluso se existir pelo menos 1 RDS)
      length(local.map_of_rds.rds_list) > 0 ? [
        {
          type   = "text"
          x      = 0
          y      = local.rds_header_y
          width  = 24
          height = 1
          properties = {
            markdown   = "# RDS Metrics\n\n"
            background = "transparent"
          }
        }
      ] : [],
      // Widgets RDS
      local.rds_widgets,

      // Cabeçalho Redis (incluso se existir pelo menos 1 Redis)
      length(local.redis_instances) > 0 ? [
        {
          type   = "text"
          x      = 0
          y      = local.redis_header_y
          width  = 24
          height = 1
          properties = {
            markdown   = "# Redis Metrics\n\n"
            background = "transparent"
          }
        }
      ] : [],
      // Widgets Redis
      local.redis_widgets,

      // Cabeçalho EFS (incluso se existir pelo menos 1 EFS)
      length(local.efs_instances) > 0 ? [
        {
          type   = "text"
          x      = 0
          y      = local.efs_header_y
          width  = 24
          height = 1
          properties = {
            markdown   = "# EFS Metrics\n\n"
            background = "transparent"
          }
        }
      ] : [],
      // Widgets EFS
      local.efs_widgets,

      // Cabeçalho ASG (incluso se existir pelo menos 1 ASG)
      length(local.asg_instances) > 0 ? [
        {
          type   = "text"
          x      = 0
          y      = local.asg_header_y
          width  = 24
          height = 1
          properties = {
            markdown   = "# Auto Scaling Group Metrics\n\n"
            background = "transparent"
          }
        }
      ] : [],
      // Widgets ASG
      local.asg_widgets
    )
  })
}

############################### ALARMES ####################################

# Transformando a lista de ARNs em um mapa para uso no for_each
locals {
  alb_map = { for index, alb_arn in data.external.load_balancers.result : "alb_${index}" => alb_arn }
}

resource "aws_sns_topic" "cloudwatch_topic" {
  count = var.create_dashboard ? 1 : 0
  name  = "${var.customer_name}-${var.environment_name}-cloudwatch-topic"

  tags = merge(local.tags, {})
}

resource "aws_sns_topic_subscription" "cloudwatch_subscriptions" {
  for_each  = var.create_dashboard ? var.cloudwatch_subscriptions : {}
  topic_arn = aws_sns_topic.cloudwatch_topic[0].arn
  protocol  = each.value.protocol
  endpoint  = each.value.endpoint
}

# Alarme para [ALB] 5XX Error usando expressão matemática
resource "aws_cloudwatch_metric_alarm" "alb_5xx_Error" {
  for_each = var.create_dashboard ? { for name, alb in data.aws_lb.application_lb : name => join("/", slice(split("/", alb.arn), 1, 4)) } : {}

  alarm_name          = "${upper(var.customer_name)}-${upper(each.key)}-5XX_STATUS_HIGH"
  alarm_description   = "Alarm for ALB 5xx Error for ${each.key}"
  evaluation_periods  = 1
  threshold           = 5
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "e1"
    expression  = "IF(m1 > 0, 100*(m2/m1), 0)"
    label       = "5xx_Percent"
    return_data = true
  }

  metric_query {
    id = "m1"
    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "RequestCount"
      dimensions = {
        LoadBalancer = each.value
      }
      period = 300
      stat   = "Sum"
      unit   = "Count"
    }
    return_data = false
  }

  metric_query {
    id = "m2"
    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "HTTPCode_Target_5XX_Count"
      dimensions = {
        LoadBalancer = each.value
      }
      period = 300
      stat   = "Sum"
      unit   = "Count"
    }
    return_data = false
  }

  alarm_actions = [aws_sns_topic.cloudwatch_topic[0].arn]
  ok_actions    = [aws_sns_topic.cloudwatch_topic[0].arn]

  tags = merge(local.tags, {})
}

# Alarme para [EC2] CPUUtilization
resource "aws_cloudwatch_metric_alarm" "ec2_cpu_utilization" {
  for_each = var.create_dashboard ? toset(data.aws_instances.existing.ids) : []

  alarm_name          = "${upper(var.customer_name)}_${upper(var.environment_name)}_EC2_${upper(data.aws_instance.detailed[each.key].tags["Name"])}_CPU-HIGH"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    InstanceId = each.value
  }

  alarm_description = "CRITICAL"
  alarm_actions     = [aws_sns_topic.cloudwatch_topic[0].arn]
  ok_actions        = [aws_sns_topic.cloudwatch_topic[0].arn] # Ação quando o valor voltar a OK

  tags = merge(local.tags, {})
}

# Definir as métricas de memória corretamente para Windows e Linux
locals {
  mem_metrics = {
    for instance_id in data.aws_instances.existing.ids :
    instance_id => lookup(data.aws_instance.detailed[instance_id].tags, "OS", "Linux") == "Windows" ? {
      name = "Memory % Committed Bytes In Use"
      dimensions = {
        InstanceId   = instance_id
        ImageId      = data.aws_instance.detailed[instance_id].ami
        InstanceType = data.aws_instance.detailed[instance_id].instance_type
        objectname   = "Memory"
      }
      } : {
      name = "mem_used_percent"
      dimensions = {
        InstanceId   = instance_id
        ImageId      = data.aws_instance.detailed[instance_id].ami
        InstanceType = data.aws_instance.detailed[instance_id].instance_type
      }
    }
  }

  disk_metrics = {
    for instance_id in data.aws_instances.existing.ids :
    instance_id => lookup(data.aws_instance.detailed[instance_id].tags, "OS", "Linux") == "Windows" ? {
      name      = "LogicalDisk % Free Space"
      threshold = 20
      dimensions = {
        InstanceId   = instance_id
        ImageId      = data.aws_instance.detailed[instance_id].ami
        InstanceType = data.aws_instance.detailed[instance_id].instance_type
        objectname   = "LogicalDisk"
        instance     = "C:"
      }
      } : {
      name      = "disk_used_percent"
      threshold = 80
      dimensions = {
        InstanceId   = instance_id
        ImageId      = data.aws_instance.detailed[instance_id].ami
        InstanceType = data.aws_instance.detailed[instance_id].instance_type
        path         = "/"
        device       = "nvme0n1p1"
        fstype       = "ext4"
      }
    }
  }
}

# Alarme para [EC2] Memory Utilization
resource "aws_cloudwatch_metric_alarm" "ec2_mem_utilization" {
  for_each = var.create_dashboard ? local.mem_metrics : {}

  alarm_name          = "${upper(var.customer_name)}_${upper(var.environment_name)}_EC2_${upper(data.aws_instance.detailed[each.key].tags["Name"])}_MEM-HIGH"
  namespace           = "CWAgent"
  metric_name         = each.value.name
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  dimensions          = each.value.dimensions

  alarm_description = "Alarm for EC2 Memory Utilization for Instance ${each.key}"
  alarm_actions     = [aws_sns_topic.cloudwatch_topic[0].arn]
  ok_actions        = [aws_sns_topic.cloudwatch_topic[0].arn]

  tags = merge(local.tags, {})
}

# Alarme para [EC2] Disk Utilization
resource "aws_cloudwatch_metric_alarm" "ec2_disk_utilization" {
  for_each = var.create_dashboard ? local.disk_metrics : {}

  alarm_name          = "${upper(var.customer_name)}_${upper(var.environment_name)}_EC2_${upper(data.aws_instance.detailed[each.key].tags["Name"])}_DISK-HIGH"
  namespace           = "CWAgent"
  metric_name         = each.value.name
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 1
  threshold           = each.value.threshold
  comparison_operator = "GreaterThanThreshold"
  dimensions          = each.value.dimensions

  alarm_description = "Alarm for EC2 Disk Utilization for Instance ${each.key}"
  alarm_actions     = [aws_sns_topic.cloudwatch_topic[0].arn]
  ok_actions        = [aws_sns_topic.cloudwatch_topic[0].arn]

  tags = merge(local.tags, {})
}


# Alarme para [EC2] StatusCheckFailed
resource "aws_cloudwatch_metric_alarm" "ec2_status_check" {
  for_each = var.create_dashboard ? toset(data.aws_instances.existing.ids) : []

  alarm_name          = "${upper(var.customer_name)}_${upper(var.environment_name)}_EC2_${upper(data.aws_instance.detailed[each.key].tags["Name"])}_STATUS-CHECK"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 1 # Status check falhado
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    InstanceId = each.value
  }

  alarm_description = "Alarm for EC2 Status Check Failed for Instance ${each.value}"
  alarm_actions     = [aws_sns_topic.cloudwatch_topic[0].arn]
  ok_actions        = [aws_sns_topic.cloudwatch_topic[0].arn] # Ação quando o valor voltar a OK

  tags = merge(local.tags, {})
}

# Alarme para [EC2] StatusCheckFailed
resource "aws_cloudwatch_metric_alarm" "ec2_status_check_ebs" {
  for_each = var.create_dashboard ? toset(data.aws_instances.existing.ids) : []

  alarm_name          = "${upper(var.customer_name)}_${upper(var.environment_name)}_EC2_${upper(data.aws_instance.detailed[each.key].tags["Name"])}_EBS-FAILED"
  metric_name         = "StatusCheckFailed_AttachedEBS"
  namespace           = "AWS/EC2"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    InstanceId = each.value
  }

  alarm_description = "Alarm for EC2 Status Check EBS Failed for Instance ${each.value}"
  alarm_actions     = [aws_sns_topic.cloudwatch_topic[0].arn]
  ok_actions        = [aws_sns_topic.cloudwatch_topic[0].arn] # Ação quando o valor voltar a OK

  tags = merge(local.tags, {})
}

resource "aws_cloudwatch_metric_alarm" "ec2_credit_balance" {
  for_each = var.create_dashboard ? {
    for id in data.aws_instances.existing.ids : id => id
    if contains(keys(local.ec2_instances_credit), data.aws_instance.detailed[id].instance_type)
  } : {}

  alarm_name          = "${upper(var.customer_name)}_${upper(var.environment_name)}_EC2_${upper(data.aws_instance.detailed[each.key].tags["Name"])}_CREDIT-USAGE"
  metric_name         = "CPUCreditBalance"
  namespace           = "AWS/EC2"
  statistic           = "Minimum"
  period              = 300
  evaluation_periods  = 3
  datapoints_to_alarm = 3
  threshold           = floor(lookup(local.ec2_instances_credit, data.aws_instance.detailed[each.key].instance_type, 0) * 0.4)
  comparison_operator = "LessThanOrEqualToThreshold"
  treat_missing_data  = "missing"
  dimensions          = { InstanceId = each.value }
  alarm_description   = "CRITICAL"
  alarm_actions       = [aws_sns_topic.cloudwatch_topic[0].arn]
  ok_actions          = [aws_sns_topic.cloudwatch_topic[0].arn]

  tags = merge(local.tags, {})
}

# Alarme para [EFS] Throughput utilization usando expressão matemática
resource "aws_cloudwatch_metric_alarm" "efs_throughput_utilization" {
  for_each = var.create_dashboard ? toset(local.efs_instances) : []

  alarm_name          = "${upper(var.customer_name)}_${upper(var.environment_name)}_EFS_${upper(each.value)}_THROUGHPUT-HIGH"
  alarm_description   = "Alarm for EFS Throughput Utilization for ${each.value}"
  evaluation_periods  = 1
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"


  metric_query {
    id          = "e1"
    expression  = "(m1/1048576)/PERIOD(m1)"
    label       = "Expression1"
    return_data = false
  }

  metric_query {
    id          = "e2"
    expression  = "m2/1048576"
    label       = "Expression2"
    return_data = false
  }

  metric_query {
    id = "m1"
    metric {
      namespace   = "AWS/EFS"
      metric_name = "MeteredIOBytes"
      dimensions = {
        FileSystemId = each.value
      }
      period = 60
      stat   = "Sum"
    }
    return_data = false
  }

  metric_query {
    id = "m2"
    metric {
      namespace   = "AWS/EFS"
      metric_name = "PermittedThroughput"
      dimensions = {
        FileSystemId = each.value
      }
      period = 60
      stat   = "Sum"
    }
    return_data = false
  }

  metric_query {
    id          = "e4"
    expression  = "((e1)*100)/(e2)"
    label       = "Throughput utilization (%)"
    return_data = true
  }

  alarm_actions = [aws_sns_topic.cloudwatch_topic[0].arn]
  ok_actions    = [aws_sns_topic.cloudwatch_topic[0].arn]

  tags = merge(local.tags, {})
}

# Alarme para [EFS] PercentIOLimit
resource "aws_cloudwatch_metric_alarm" "efs_percent_io_limit" {
  for_each = var.create_dashboard ? toset(local.efs_instances) : []

  alarm_name          = "${upper(var.customer_name)}_${upper(var.environment_name)}_EFS_${upper(each.value)}_IO-LIMIT-HIGH"
  namespace           = "AWS/EFS"
  metric_name         = "PercentIOLimit"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    FileSystemId = each.value
  }

  alarm_description = "Alarm for EFS IO Limit for ${each.value}"
  alarm_actions     = [aws_sns_topic.cloudwatch_topic[0].arn]
  ok_actions        = [aws_sns_topic.cloudwatch_topic[0].arn]

  tags = merge(local.tags, {})
}

resource "aws_cloudwatch_metric_alarm" "efs_connections_low" {
  for_each = var.create_dashboard ? toset(local.efs_instances) : []

  alarm_name          = "${upper(var.customer_name)}_${upper(var.environment_name)}_EFS_${upper(each.value)}_CONN-LOW"
  namespace           = "AWS/EFS"
  metric_name         = "ClientConnections"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "LessThanOrEqualToThreshold"

  dimensions = {
    FileSystemId = each.value
  }

  alarm_description = "Alarm for EFS Connections for ${each.value}"
  alarm_actions     = [aws_sns_topic.cloudwatch_topic[0].arn]
  ok_actions        = [aws_sns_topic.cloudwatch_topic[0].arn]

  tags = merge(local.tags, {})
}

# Alarme para [REDIS] CPU Utilization
resource "aws_cloudwatch_metric_alarm" "redis_cpu_utilization" {
  for_each = var.create_dashboard ? toset(local.redis_instances) : []

  alarm_name          = "${upper(var.customer_name)}_${upper(var.environment_name)}_REDIS_${upper(each.value)}_CPU-HIGH"
  namespace           = "AWS/ElastiCache"
  metric_name         = "EngineCPUUtilization"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    CacheClusterId = each.value
  }

  alarm_description = "Alarm for Redis CPU Utilization for ${each.value}"
  alarm_actions     = [aws_sns_topic.cloudwatch_topic[0].arn]
  ok_actions        = [aws_sns_topic.cloudwatch_topic[0].arn]

  tags = merge(local.tags, {})
}

# Alarme para [ASG] Active Instances (baseado no alert do widget)
resource "aws_cloudwatch_metric_alarm" "asg_active_instances" {
  for_each = var.create_dashboard ? toset(local.asg_instances) : []

  alarm_name          = "${upper(var.customer_name)}_${upper(var.environment_name)}_ASG_${upper(each.value)}_INSTANCES-LOW"
  namespace           = "AWS/AutoScaling"
  metric_name         = "GroupInServiceInstances"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "LessThanOrEqualToThreshold"

  dimensions = {
    AutoScalingGroupName = each.value
  }

  alarm_description = "Alarm for ASG Active Instances for ${each.value}"
  alarm_actions     = [aws_sns_topic.cloudwatch_topic[0].arn]
  ok_actions        = [aws_sns_topic.cloudwatch_topic[0].arn]

  tags = merge(local.tags, {})
}

# RDS CPU Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "rds_cpu_utilization" {
  for_each = var.create_dashboard ? { for idx, rds in local.RDS.t_instance_list : rds["id"] => rds if length(rds["id"]) > 0 } : {}

  alarm_name          = "${upper(var.customer_name)}_${upper(var.environment_name)}_RDS_${upper(each.value.id)}_CPU-HIGH"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 80
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions          = { DBInstanceIdentifier = each.value.id }
  alarm_description   = "CRITICAL"
  alarm_actions       = [aws_sns_topic.cloudwatch_topic[0].arn]
  ok_actions          = [aws_sns_topic.cloudwatch_topic[0].arn]

  tags = merge(local.tags, {})
}

# RDS Memory Alarm
resource "aws_cloudwatch_metric_alarm" "rds_memory" {
  for_each = var.create_dashboard ? { for idx, rds in local.RDS.t_instance_list : rds["id"] => rds if length(rds["id"]) > 0 } : {}

  alarm_name         = "${upper(var.customer_name)}_${upper(var.environment_name)}_RDS_${upper(each.value.id)}_MEM-LOW"
  metric_name        = "FreeableMemory"
  namespace          = "AWS/RDS"
  statistic          = "Minimum"
  period             = 60
  evaluation_periods = 1
  # Alerta quando memória livre for menor que 20% da memória total da instância
  threshold           = lookup(local.db_instance_memory, each.value.type, 1) * 1024 * 1024 * 1024 * 0.2 # 20% da memória em bytes
  comparison_operator = "LessThanThreshold"
  dimensions          = { DBInstanceIdentifier = each.value.id }
  alarm_description   = "CRITICAL"
  alarm_actions       = [aws_sns_topic.cloudwatch_topic[0].arn]
  ok_actions          = [aws_sns_topic.cloudwatch_topic[0].arn]

  tags = merge(local.tags, {})
}

# RDS Storage Alarm
resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  for_each = var.create_dashboard ? { for idx, rds in local.RDS.t_instance_list : rds["id"] => rds if length(rds["id"]) > 0 } : {}

  alarm_name         = "${upper(var.customer_name)}_${upper(var.environment_name)}_RDS_${upper(each.value.id)}_STORAGE-LOW"
  metric_name        = "FreeStorageSpace"
  namespace          = "AWS/RDS"
  statistic          = "Minimum"
  period             = 60
  evaluation_periods = 1
  # Alerta quando espaço livre for menor que 20% do armazenamento total
  threshold           = each.value.allocated_storage_gb * 1024 * 1024 * 1024 * 0.2 # 20% do armazenamento em bytes
  comparison_operator = "LessThanThreshold"
  dimensions          = { DBInstanceIdentifier = each.value.id }
  alarm_description   = "CRITICAL"
  alarm_actions       = [aws_sns_topic.cloudwatch_topic[0].arn]
  ok_actions          = [aws_sns_topic.cloudwatch_topic[0].arn]

  tags = merge(local.tags, {})
}

# RDS Database Connections Alarm
resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  for_each = var.create_dashboard ? { for idx, rds in local.RDS.t_instance_list : rds["id"] => rds if length(rds["id"]) > 0 } : {}

  alarm_name          = "${upper(var.customer_name)}_${upper(var.environment_name)}_RDS_${upper(each.value.id)}_CONN-HIGH"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 1
  threshold           = local.t_instance_max_connections[each.value.id]
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions          = { DBInstanceIdentifier = each.value.id }
  alarm_description   = "CRITICAL"
  alarm_actions       = [aws_sns_topic.cloudwatch_topic[0].arn]
  ok_actions          = [aws_sns_topic.cloudwatch_topic[0].arn]

  tags = merge(local.tags, {})
}

# Alarmes para instâncias RDS não-T

# RDS CPU Utilization Alarm (não-T)
resource "aws_cloudwatch_metric_alarm" "rds_std_cpu_utilization" {
  for_each = var.create_dashboard ? { for idx, rds in local.RDS.rds_list : rds["id"] => rds if length(rds["id"]) > 0 } : {}

  alarm_name          = "${upper(var.customer_name)}_${upper(var.environment_name)}_RDS_${upper(each.value.id)}_CPU-HIGH"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 80
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions          = { DBInstanceIdentifier = each.value.id }
  alarm_description   = "CRITICAL"
  alarm_actions       = [aws_sns_topic.cloudwatch_topic[0].arn]
  ok_actions          = [aws_sns_topic.cloudwatch_topic[0].arn]

  tags = merge(local.tags, {})
}

# RDS Memory Alarm (não-T)
resource "aws_cloudwatch_metric_alarm" "rds_std_memory" {
  for_each = var.create_dashboard ? { for idx, rds in local.RDS.rds_list : rds["id"] => rds if length(rds["id"]) > 0 } : {}

  alarm_name         = "${upper(var.customer_name)}_${upper(var.environment_name)}_RDS_${upper(each.value.id)}_MEM-LOW"
  metric_name        = "FreeableMemory"
  namespace          = "AWS/RDS"
  statistic          = "Minimum"
  period             = 60
  evaluation_periods = 1
  # Alerta quando memória livre for menor que 20% da memória total da instância
  threshold           = lookup(local.db_instance_memory, each.value.type, 16) * 1024 * 1024 * 1024 * 0.2 # 20% da memória em bytes
  comparison_operator = "LessThanThreshold"
  dimensions          = { DBInstanceIdentifier = each.value.id }
  alarm_description   = "CRITICAL"
  alarm_actions       = [aws_sns_topic.cloudwatch_topic[0].arn]
  ok_actions          = [aws_sns_topic.cloudwatch_topic[0].arn]

  tags = merge(local.tags, {})
}

# RDS Storage Alarm (não-T)
resource "aws_cloudwatch_metric_alarm" "rds_std_storage" {
  for_each = var.create_dashboard ? { for idx, rds in local.RDS.rds_list : rds["id"] => rds if length(rds["id"]) > 0 } : {}

  alarm_name         = "${upper(var.customer_name)}_${upper(var.environment_name)}_RDS_${upper(each.value.id)}_STORAGE-LOW"
  metric_name        = "FreeStorageSpace"
  namespace          = "AWS/RDS"
  statistic          = "Minimum"
  period             = 60
  evaluation_periods = 1
  # Alerta quando espaço livre for menor que 20% do armazenamento total
  threshold           = each.value.allocated_storage_gb * 1024 * 1024 * 1024 * 0.2 # 20% do armazenamento em bytes
  comparison_operator = "LessThanThreshold"
  dimensions          = { DBInstanceIdentifier = each.value.id }
  alarm_description   = "CRITICAL"
  alarm_actions       = [aws_sns_topic.cloudwatch_topic[0].arn]
  ok_actions          = [aws_sns_topic.cloudwatch_topic[0].arn]

  tags = merge(local.tags, {})
}

# RDS Database Connections Alarm (não-T)
resource "aws_cloudwatch_metric_alarm" "rds_std_connections" {
  for_each = var.create_dashboard ? { for idx, rds in local.RDS.rds_list : rds["id"] => rds if length(rds["id"]) > 0 } : {}

  alarm_name          = "${upper(var.customer_name)}_${upper(var.environment_name)}_RDS_${upper(each.value.id)}_CONN-HIGH"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 1
  threshold           = local.std_instance_max_connections[each.value.id]
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions          = { DBInstanceIdentifier = each.value.id }
  alarm_description   = "CRITICAL"
  alarm_actions       = [aws_sns_topic.cloudwatch_topic[0].arn]
  ok_actions          = [aws_sns_topic.cloudwatch_topic[0].arn]

  tags = merge(local.tags, {})
}