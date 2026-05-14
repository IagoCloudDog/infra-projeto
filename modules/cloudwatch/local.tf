locals {
  tags = var.tags
}

locals {
  map_of_rds = {
    aurora_list            = split(", ", data.external.RDS.result["Aurora_list"])
    rds_list               = split(", ", data.external.RDS.result["RDS"])
    aurora_serverless_list = split(", ", data.external.RDS.result["Aurora_serverless_list"])
  }
  alb_target_groups = {
    for lb_name, _ in data.aws_lb.application_lb :
    lb_name => [
      for tg_arn in split(",", lookup(data.external.Map_of_targetGroups.result, lb_name, "")) :
      "targetgroup/${join("/", slice(split("/", tg_arn), 1, 3))}" # Extrai somente `targetgroup/{nome}/{id}`
      if startswith(tg_arn, "arn:aws:elasticloadbalancing")
    ]
  }
  nlb_target_groups = {
    for lb_name, _ in data.aws_lb.network_lb :
    lb_name => [
      for tg_arn in split(",", lookup(data.external.Map_of_targetGroups.result, lb_name, "")) :
      "targetgroup/${join("/", slice(split("/", tg_arn), 1, 3))}" # Extrai somente `targetgroup/{nome}/{id}`
      if startswith(tg_arn, "arn:aws:elasticloadbalancing")
    ]
  }
}

locals {
  # Alturas de cada seção
  alb_block_height = length(data.aws_lb.application_lb) * 8
  nlb_block_height = length(data.aws_lb.network_lb) * 8
  ec2_block_height = length(data.aws_instances.existing.ids) * 7
  # Se cada RDS ocupar 14 unidades de altura:
  rds_block_height   = length(local.map_of_rds.rds_list) * 14
  redis_block_height = length(local.redis_instances) * 8
  efs_block_height   = length(local.efs_instances) * 12 # Altura para os widgets EFS
  asg_block_height   = length(local.asg_instances) * 8  # Altura para os widgets ASG

  # Offsets (posição Y inicial de cada seção)
  alb_offset     = 1                                               # ALB: logo abaixo do cabeçalho do dashboard
  nlb_header_y   = local.alb_offset + local.alb_block_height       # Cabeçalho NLB logo após ALB
  ec2_header_y   = local.nlb_header_y + 1 + local.nlb_block_height # Cabeçalho EC2 após NLB (1 linha para o título)
  rds_header_y   = local.ec2_header_y + 1 + local.ec2_block_height # Cabeçalho RDS após EC2
  rds_t_header_y = local.rds_header_y + length(local.RDS.rds_list) * 14 + 4
  redis_header_y = local.rds_t_header_y + length(local.RDS.t_instance_list) * 14 + 4 # Cabeçalho Redis após RDS
  efs_header_y   = local.redis_header_y + 1 + local.redis_block_height               # Cabeçalho EFS após Redis
  asg_header_y   = local.efs_header_y + 1 + local.efs_block_height                   # Cabeçalho ASG após EFS
}

locals {
  result = data.external.RDS

  RDS = {
    rds_list               = length(local.result.result["RDS"]) > 0 && local.result.result["RDS"] != "" ? split(", ", local.result.result["RDS"]) : []
    rds_without_t_list     = length(local.result.result["RDS"]) > 0 && local.result.result["RDS"] != "" ? split(", ", local.result.result["RDS"]) : []
    aurora_list            = length(local.result.result["Aurora_list"]) > 0 && local.result.result["Aurora_list"] != "" ? split(", ", local.result.result["Aurora_list"]) : []
    aurora_serverless_list = length(local.result.result["Aurora_serverless_list"]) > 0 && local.result.result["Aurora_serverless_list"] != "" ? split(", ", local.result.result["Aurora_serverless_list"]) : []
    t_instance_list = (
      length(local.result.result["T_instances"]) > 0 && local.result.result["T_instances"] != ""
    ) ? jsondecode(local.result.result["T_instances"]) : []
  }

  t_instance_max_connections = {
    for inst in local.RDS.t_instance_list :
    inst["id"] => floor(inst["max_connections"] * 0.8) # Aplica 80% do max_connections
  }

  std_instance_max_connections = {
    for inst in local.RDS.rds_list :
    inst["id"] => floor(inst["max_connections"] * 0.8)
  }


  # Lista de todas as instâncias RDS com informações de memória
  all_rds_instances = (
    length(local.result.result["All_RDS_instances"]) > 0 && local.result.result["All_RDS_instances"] != ""
  ) ? jsondecode(local.result.result["All_RDS_instances"]) : []

  # Mapa de memória das instâncias RDS (20% da memória total em bytes)
  rds_memory_alert_threshold = {
    for inst in local.all_rds_instances :
    inst["id"] => tonumber(lookup(inst, "memory_gb", 8)) * 1024 * 1024 * 1024 * 0.2 # 20% da memória em bytes
  }

  # Mapa de armazenamento das instâncias RDS (20% do armazenamento total em bytes - limite para alerta)
  rds_storage_alert_threshold = {
    for inst in local.all_rds_instances :
    inst["id"] => tonumber(lookup(inst, "allocated_storage_gb", 20)) * 1024 * 1024 * 1024 * 0.2 # 20% do armazenamento em bytes
  }

  # Lista de instâncias Redis
  redis_instances = length(data.external.Redis.result["Redis_list"]) > 0 && data.external.Redis.result["Redis_list"] != "" ? split(", ", data.external.Redis.result["Redis_list"]) : []

  # Lista de instâncias EFS
  efs_instances = length(data.external.EFS.result["EFS_list"]) > 0 && data.external.EFS.result["EFS_list"] != "" ? split(", ", data.external.EFS.result["EFS_list"]) : [] # Lista vazia se não houver EFS

  # Lista de Auto Scaling Groups
  asg_instances = keys(data.external.ASG.result)
}

locals {
  ec2_instances_credit = {
    "t2.nano"     = 144
    "t2.micro"    = 144
    "t2.small"    = 288
    "t2.medium"   = 576
    "t2.large"    = 864
    "t2.xlarge"   = 1296
    "t2.2xlarge"  = 1958.4
    "t3.nano"     = 144
    "t3.micro"    = 288
    "t3.small"    = 576
    "t3.medium"   = 576
    "t3.large"    = 864
    "t3.xlarge"   = 2304
    "t3.2xlarge"  = 4608
    "t3a.nano"    = 144
    "t3a.micro"   = 288
    "t3a.small"   = 576
    "t3a.medium"  = 576
    "t3a.large"   = 864
    "t3a.xlarge"  = 2304
    "t3a.2xlarge" = 4608
    "t4g.nano"    = 144
    "t4g.micro"   = 288
    "t4g.small"   = 576
    "t4g.medium"  = 576
    "t4g.large"   = 864
    "t4g.xlarge"  = 2304
    "t4g.2xlarge" = 4608
  }

  rds_instances_credit = {
    "db.t2.micro"    = 144
    "db.t2.small"    = 288
    "db.t2.medium"   = 576
    "db.t3.micro"    = 144
    "db.t3.small"    = 288
    "db.t3.medium"   = 576
    "db.t3.large"    = 864
    "db.t3.xlarge"   = 2304
    "db.t3.2xlarge"  = 4608
    "db.t4g.micro"   = 144
    "db.t4g.small"   = 288
    "db.t4g.medium"  = 576
    "db.t4g.large"   = 864
    "db.t4g.xlarge"  = 2304
    "db.t4g.2xlarge" = 4608
  }

  db_instance_memory = {
    "db.t3.micro"    = 1, "db.t3.small" = 2, "db.t3.medium" = 4, "db.t3.large" = 8, "db.t3.xlarge" = 16, "db.t3.2xlarge" = 32,
    "db.t4g.micro"   = 1, "db.t4g.small" = 2, "db.t4g.medium" = 4, "db.t4g.large" = 8, "db.t4g.xlarge" = 16, "db.t4g.2xlarge" = 32,
    "db.m5.large"    = 8, "db.m5.xlarge" = 16, "db.m5.2xlarge" = 32, "db.m5.4xlarge" = 64, "db.m5.8xlarge" = 128, "db.m5.12xlarge" = 192, "db.m5.16xlarge" = 256, "db.m5.24xlarge" = 384,
    "db.m6g.large"   = 8, "db.m6g.xlarge" = 16, "db.m6g.2xlarge" = 32, "db.m6g.4xlarge" = 64, "db.m6g.8xlarge" = 128, "db.m6g.12xlarge" = 192, "db.m6g.16xlarge" = 256,
    "db.r5.large"    = 16, "db.r5.xlarge" = 32, "db.r5.2xlarge" = 64, "db.r5.4xlarge" = 128, "db.r5.8xlarge" = 256, "db.r5.12xlarge" = 384, "db.r5.16xlarge" = 512, "db.r5.24xlarge" = 768,
    "db.r6g.large"   = 16, "db.r6g.xlarge" = 32, "db.r6g.2xlarge" = 64, "db.r6g.4xlarge" = 128, "db.r6g.8xlarge" = 256, "db.r6g.12xlarge" = 384, "db.r6g.16xlarge" = 512,
    "db.x1.16xlarge" = 976, "db.x1.32xlarge" = 1952,
    "db.x2g.large"   = 16, "db.x2g.xlarge" = 32, "db.x2g.2xlarge" = 64, "db.x2g.4xlarge" = 128, "db.x2g.8xlarge" = 256, "db.x2g.12xlarge" = 384, "db.x2g.16xlarge" = 512,
    "db.z1d.large"   = 16, "db.z1d.xlarge" = 32, "db.z1d.2xlarge" = 64, "db.z1d.3xlarge" = 96, "db.z1d.6xlarge" = 192, "db.z1d.12xlarge" = 384,
    "db.m7g.large"   = 16, "db.m7g.xlarge" = 32, "db.m7g.2xlarge" = 64, "db.m7g.4xlarge" = 128, "db.m7g.8xlarge" = 256, "db.m7g.12xlarge" = 384, "db.m7g.16xlarge" = 512,
    "db.r7g.large"   = 16, "db.r7g.xlarge" = 32, "db.r7g.2xlarge" = 64, "db.r7g.4xlarge" = 128, "db.r7g.8xlarge" = 256, "db.r7g.12xlarge" = 384, "db.r7g.16xlarge" = 512
  }
}

locals {
  # Widgets de Application LB (ALB)
  application_lb_widgets = flatten([
    for lb_name, alb in data.aws_lb.application_lb : [
      {
        type   = "text"
        x      = 0
        y      = local.alb_offset + index(keys(data.aws_lb.application_lb), lb_name) * 8
        width  = 24
        height = 2
        properties = {
          markdown   = "## ${lb_name}\n\n[button:primary:${lb_name}](https://${data.aws_region.current.name}.console.aws.amazon.com/ec2/home?region=${data.aws_region.current.name}#LoadBalancer:loadBalancerName=${alb.name})"
          background = "transparent"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = local.alb_offset + 2 + index(keys(data.aws_lb.application_lb), lb_name) * 8
        width  = 6
        height = 6
        properties = {
          metrics = [["AWS/ApplicationELB", "RequestCount", "LoadBalancer", join("/", slice(split("/", alb.arn), 1, 4)), { "color" : "#17caf6" }]]
          view    = "timeSeries"
          stat    = "Sum"
          region  = data.aws_region.current.name
          period  = 60
          title   = "[ALB] RequestCount"
        }
      },
      {
        type   = "metric"
        x      = 6
        y      = local.alb_offset + 2 + index(keys(data.aws_lb.application_lb), lb_name) * 8
        width  = 6
        height = 6
        properties = {
          metrics = [["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", join("/", slice(split("/", alb.arn), 1, 4)), { "color" : "#17caf6" }]]
          view    = "timeSeries"
          stat    = "Average"
          region  = data.aws_region.current.name
          period  = 60
          title   = "[ALB] Latency"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = local.alb_offset + 2 + index(keys(data.aws_lb.application_lb), lb_name) * 8
        width  = 6
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", join("/", slice(split("/", alb.arn), 1, 4)), { "id" : "m1", "visible" : false }],
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", join("/", slice(split("/", alb.arn), 1, 4)), { "id" : "m2", "visible" : false }],
            [{ "expression" : "IF(m1 > 0, 100*(m2/m1), 0)", "label" : "5xx_Percent", "id" : "e1" }]
          ]
          view   = "timeSeries"
          stat   = "Sum"
          region = data.aws_region.current.name
          period = 300
          title  = "[ALB] 5XX Error"
          yAxis = {
            left = {
              max       = 100,
              label     = "Percent",
              showUnits = false
            },
            right = {
              label     = "",
              showUnits = false
            }
          }
          annotations = {
            horizontal = [
              {
                color = "#ff0000"
                label = "Alert"
                value = 5
                fill  = "above"
              }
            ]
          }
        }
      },
      {
        type   = "metric"
        x      = 18
        y      = local.alb_offset + 2 + index(keys(data.aws_lb.application_lb), lb_name) * 8
        width  = 6
        height = 6
        properties = {
          metrics = [
            for tg_arn in local.alb_target_groups[lb_name] : [
              "AWS/ApplicationELB",
              "HealthyHostCount",
              "TargetGroup", tg_arn,
              "LoadBalancer", join("/", slice(split("/", alb.arn), 1, 4))
            ]
          ],
          view   = "bar",
          stat   = "Maximum",
          region = data.aws_region.current.name,
          period = 60,
          title  = "[ALB] HealthyHost"
        }
      }
    ]
  ])

  # Widgets de Network LB (NLB)
  network_lb_widgets = flatten([
    for nlb_name, nlb in data.aws_lb.network_lb : [
      {
        type   = "text"
        x      = 0
        y      = local.nlb_header_y + 1 + index(keys(data.aws_lb.network_lb), nlb_name) * 8
        width  = 24
        height = 2
        properties = {
          markdown   = "## ${nlb.name}\n\n[button:primary:${nlb.name}](https://${data.aws_region.current.name}.console.aws.amazon.com/ec2/home?region=${data.aws_region.current.name}#LoadBalancer:loadBalancerName=${nlb.name})"
          background = "transparent"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = local.nlb_header_y + 1 + index(keys(data.aws_lb.network_lb), nlb_name) * 8
        width  = 5
        height = 6
        properties = {
          title   = "[NLB] New Flow Count"
          region  = data.aws_region.current.name
          metrics = [["AWS/NetworkELB", "NewFlowCount", "LoadBalancer", join("/", slice(split("/", element(split(":", nlb.arn), 5)), 1, 4)), { "color" : "#17caf6" }]]
          stat    = "Maximum"
          period  = 60
        }
      },
      {
        type   = "metric"
        x      = 5
        y      = local.nlb_header_y + 1 + index(keys(data.aws_lb.network_lb), nlb_name) * 8
        width  = 5
        height = 6
        properties = {
          title   = "[NLB] Active Flow Count"
          region  = data.aws_region.current.name
          metrics = [["AWS/NetworkELB", "ActiveFlowCount", "LoadBalancer", join("/", slice(split("/", element(split(":", nlb.arn), 5)), 1, 4)), { "color" : "#17caf6" }]]
          stat    = "Sum"
          period  = 60
        }
      },
      {
        type   = "metric"
        x      = 10
        y      = local.nlb_header_y + 1 + index(keys(data.aws_lb.network_lb), nlb_name) * 8
        width  = 5
        height = 6
        properties = {
          title   = "[NLB] ConsumedLCUs"
          region  = data.aws_region.current.name
          metrics = [["AWS/NetworkELB", "ConsumedLCUs", "LoadBalancer", join("/", slice(split("/", element(split(":", nlb.arn), 5)), 1, 4)), { "color" : "#17caf6" }]]
          stat    = "Maximum"
          period  = 60
        }
      },
      {
        type   = "metric"
        x      = 15
        y      = local.nlb_header_y + 1 + index(keys(data.aws_lb.network_lb), nlb_name) * 8
        width  = 5
        height = 6
        properties = {
          title   = "[NLB] Processed Packets"
          region  = data.aws_region.current.name
          metrics = [["AWS/NetworkELB", "ProcessedPackets", "LoadBalancer", join("/", slice(split("/", element(split(":", nlb.arn), 5)), 1, 4)), { "color" : "#17caf6" }]]
          stat    = "Sum"
          period  = 60
        }
      },
      {
        type   = "metric"
        x      = 20
        y      = local.nlb_header_y + 1 + index(keys(data.aws_lb.network_lb), nlb_name) * 8
        width  = 4
        height = 6
        properties = {
          title  = "[NLB] HealthyHostCount"
          region = data.aws_region.current.name
          metrics = [
            for tg_arn in local.nlb_target_groups[nlb_name] : [
              "AWS/ApplicationELB",
              "HealthyHostCount",
              "TargetGroup", tg_arn,
              "LoadBalancer", join("/", slice(split("/", element(split(":", nlb.arn), 5)), 1, 4))
            ]
          ],
          stat   = "Sum",
          period = 60
        }
      },
    ]
  ])

  ec2_widgets = flatten([
    for i, instance_id in tolist(data.aws_instances.existing.ids) : concat(
      [
        {
          type   = "text"
          x      = 0
          y      = local.ec2_header_y + 1 + i * 7
          width  = 24
          height = 2
          properties = {
            markdown   = "## ${lookup(data.aws_instance.detailed[instance_id].tags, "Name", instance_id)}\n[button:primary:${lookup(data.aws_instance.detailed[instance_id].tags, "Name", instance_id)}](https://${data.aws_region.current.name}.console.aws.amazon.com/ec2/home?region=${data.aws_region.current.name}#InstanceDetails:instanceId=${instance_id})"
            background = "transparent"
          }
        }
      ],
      !startswith(data.aws_instance.detailed[instance_id].instance_type, "t") ? [
        # --- WIDGETS PARA INSTÂNCIAS NÃO-'t' ---
        { # CPU
          type   = "metric"
          x      = 0
          y      = local.ec2_header_y + 3 + i * 7
          width  = 4
          height = 6
          properties = {
            title       = "[EC2] CPU Utilization"
            region      = data.aws_region.current.name
            metrics     = [["AWS/EC2", "CPUUtilization", "InstanceId", instance_id, { "color" : "#17caf6" }]]
            stat        = "Maximum"
            period      = 60
            yAxis       = { left = { min = 0, max = 100 } }
            annotations = { horizontal = [{ color = "#ff0000", label = "Alert", value = 80, fill = "above" }] }
          }
        },
        { # Memória (Apenas Linux)
          type   = "metric"
          x      = 4
          y      = local.ec2_header_y + 3 + i * 7
          width  = 4
          height = 6
          properties = {
            title  = "[EC2] Memory Utilization"
            region = data.aws_region.current.name
            metrics = [
              ["CWAgent", "mem_used_percent", "InstanceId", instance_id, "ImageId", data.aws_instance.detailed[instance_id].ami, "InstanceType", data.aws_instance.detailed[instance_id].instance_type, { "color" : "#17caf6" }]
            ]
            stat        = "Maximum"
            period      = 60
            yAxis       = { left = { min = 0, max = 100 } }
            annotations = { horizontal = [{ color = "#ff0000", label = "Alert", value = 80, fill = "above" }] }
          }
        },
        { # Disco (Apenas Linux)
          type   = "metric"
          x      = 8
          y      = local.ec2_header_y + 3 + i * 7
          width  = 4
          height = 6
          properties = {
            title  = "[EC2] Disk Utilization"
            region = data.aws_region.current.name
            metrics = [
              ["CWAgent", "disk_used_percent", "path", "/", "InstanceId", instance_id, "ImageId", data.aws_instance.detailed[instance_id].ami, "InstanceType", data.aws_instance.detailed[instance_id].instance_type, "device", "nvme0n1p1", "fstype", "ext4", { "color" : "#17caf6" }]
            ]
            stat        = "Maximum"
            period      = 60
            yAxis       = { left = { min = 0, max = 100 } }
            annotations = { horizontal = [{ color = "#ff0000", label = "Alert", value = 80, fill = "above" }] }
          }
        },
        { # Rede
          type   = "metric"
          x      = 12
          y      = local.ec2_header_y + 3 + i * 7
          width  = 4
          height = 6
          properties = {
            title  = "[EC2] Network In/Out"
            region = data.aws_region.current.name
            metrics = [
              ["AWS/EC2", "NetworkIn", "InstanceId", instance_id, { "color" : "#17caf6" }],
              ["AWS/EC2", "NetworkOut", "InstanceId", instance_id, { "color" : "#f66917" }]
            ]
            stat        = "Maximum"
            period      = 60
            annotations = { horizontal = [] }
          }
        },
        { # Status Check
          type   = "metric"
          x      = 16
          y      = local.ec2_header_y + 3 + i * 7
          width  = 4
          height = 6
          properties = {
            title       = "[EC2] Status Check"
            region      = data.aws_region.current.name
            metrics     = [["AWS/EC2", "StatusCheckFailed", "InstanceId", instance_id, { "color" : "#17caf6" }]]
            stat        = "Maximum"
            period      = 60
            annotations = { horizontal = [{ color = "#ff0000", label = "Alert", value = 1, fill = "above" }] }
          }
        },
        { # Status Check EBS
          type   = "metric"
          x      = 20
          y      = local.ec2_header_y + 3 + i * 7
          width  = 4
          height = 6
          properties = {
            title       = "[EC2] Status Check EBS"
            region      = data.aws_region.current.name
            metrics     = [["AWS/EC2", "StatusCheckFailed_AttachedEBS", "InstanceId", instance_id, { "color" : "#17caf6" }]]
            stat        = "Maximum"
            period      = 60
            annotations = { horizontal = [{ color = "#ff0000", label = "Alert", value = 1, fill = "above" }] }
          }
        }
        ] : [
        # --- WIDGETS PARA INSTÂNCIAS 't' ---
        { # CPU
          type   = "metric"
          x      = 0
          y      = local.ec2_header_y + 3 + i * 7
          width  = 4
          height = 6
          properties = {
            title       = "[EC2] CPU Utilization"
            region      = data.aws_region.current.name
            metrics     = [["AWS/EC2", "CPUUtilization", "InstanceId", instance_id, { "color" : "#17caf6" }]]
            stat        = "Maximum"
            period      = 60
            yAxis       = { left = { min = 0, max = 100 } }
            annotations = { horizontal = [{ color = "#ff0000", label = "Alert", value = 80, fill = "above" }] }
          }
        },
        { # Memória (Apenas Linux)
          type   = "metric"
          x      = 4
          y      = local.ec2_header_y + 3 + i * 7
          width  = 4
          height = 6
          properties = {
            title  = "[EC2] Memory Utilization"
            region = data.aws_region.current.name
            metrics = [
              ["CWAgent", "mem_used_percent", "InstanceId", instance_id, "ImageId", data.aws_instance.detailed[instance_id].ami, "InstanceType", data.aws_instance.detailed[instance_id].instance_type, { "color" : "#17caf6" }]
            ]
            stat        = "Maximum"
            period      = 60
            yAxis       = { left = { min = 0, max = 100 } }
            annotations = { horizontal = [{ color = "#ff0000", label = "Alert", value = 80, fill = "above" }] }
          }
        },
        { # Disco (Apenas Linux)
          type   = "metric"
          x      = 8
          y      = local.ec2_header_y + 3 + i * 7
          width  = 4
          height = 6
          properties = {
            title  = "[EC2] Disk Utilization"
            region = data.aws_region.current.name
            metrics = [
              ["CWAgent", "disk_used_percent", "path", "/", "InstanceId", instance_id, "ImageId", data.aws_instance.detailed[instance_id].ami, "InstanceType", data.aws_instance.detailed[instance_id].instance_type, "device", "nvme0n1p1", "fstype", "ext4", { "color" : "#17caf6" }]
            ]
            stat        = "Maximum"
            period      = 60
            yAxis       = { left = { min = 0, max = 100 } }
            annotations = { horizontal = [{ color = "#ff0000", label = "Alert", value = 80, fill = "above" }] }
          }
        },
        { # Crédito
          type   = "metric"
          x      = 12
          y      = local.ec2_header_y + 3 + i * 7
          width  = 4
          height = 6
          properties = {
            title  = "[EC2] Credit Utilization"
            region = data.aws_region.current.name
            metrics = [
              ["AWS/EC2", "CPUCreditUsage", "InstanceId", instance_id, { "color" : "#17caf6" }],
              ["AWS/EC2", "CPUCreditBalance", "InstanceId", instance_id, { "color" : "#f66917" }]
            ]
            stat        = "Maximum"
            period      = 60
            annotations = { horizontal = [{ color = "#ff0000", label = "Alert", value = floor(lookup(local.ec2_instances_credit, data.aws_instance.detailed[instance_id].instance_type, 0) * 0.4), fill = "above" }] }
          }
        },
        { # Rede
          type   = "metric"
          x      = 16
          y      = local.ec2_header_y + 3 + i * 7
          width  = 4
          height = 6
          properties = {
            title  = "[EC2] Network In/Out"
            region = data.aws_region.current.name
            metrics = [
              ["AWS/EC2", "NetworkIn", "InstanceId", instance_id, { "color" : "#17caf6" }],
              ["AWS/EC2", "NetworkOut", "InstanceId", instance_id, { "color" : "#f66917" }]
            ]
            stat        = "Maximum"
            period      = 60
            annotations = { horizontal = [] }
          }
        },
        { # Status Check
          type   = "metric"
          x      = 20
          y      = local.ec2_header_y + 3 + i * 7
          width  = 4
          height = 6
          properties = {
            title  = "[EC2] Status Check Failed"
            region = data.aws_region.current.name
            metrics = [
              ["AWS/EC2", "StatusCheckFailed", "InstanceId", instance_id, { "color" : "#17caf6" }],
              ["AWS/EC2", "StatusCheckFailed_AttachedEBS", "InstanceId", instance_id, { "color" : "#d62728" }]
            ]
            stat        = "Maximum"
            period      = 60
            annotations = { horizontal = [{ color = "#ff0000", label = "Alert", value = 1, fill = "above" }] }
          }
        }
      ]
    )
  ])

  rds_widgets = concat(
    // Primeiro grupo: local.RDS.t_instance_list
    flatten([
      for i, rds_instance in tolist(local.RDS.t_instance_list) : concat(
        [
          // Cabeçalho da instância
          {
            type   = "text"
            x      = 0
            y      = local.rds_t_header_y + 1 + i * 14
            width  = 24
            height = 2
            properties = {
              markdown   = "## ${rds_instance.id}\n[button:primary:${rds_instance.id}](https://${data.aws_region.current.name}.console.aws.amazon.com/rds/home?region=${data.aws_region.current.name}#database:id=${rds_instance.id})"
              background = "transparent"
            }
          }
        ],
        [
          // CPU Utilization
          {
            type   = "metric"
            x      = 0
            y      = local.rds_t_header_y + 1 + i * 14
            width  = 4
            height = 6
            properties = {
              metrics = [["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", rds_instance.id, { "color" : "#17caf6" }]]
              view    = "timeSeries"
              stat    = "Average"
              region  = data.aws_region.current.name
              period  = 60
              title   = "[RDS] CPU Utilization"
              yAxis   = { left = { min = 0, max = 100 } }
              annotations = {
                horizontal = [
                  {
                    color = "#ff0000"
                    label = "Alert"
                    value = 80
                    fill  = "above"
                  }
                ]
              }
            }
          },
          // Memory Utilization
          {
            type   = "metric"
            x      = 4
            y      = local.rds_t_header_y + 1 + i * 14
            width  = 4
            height = 6
            properties = {
              metrics = [["AWS/RDS", "FreeableMemory", "DBInstanceIdentifier", rds_instance.id, { "color" : "#17caf6" }]]
              view    = "timeSeries"
              stat    = "Minimum"
              region  = data.aws_region.current.name
              period  = 60
              title   = "[RDS] Memory Utilization"
              yAxis   = { left = { min = 0, max = rds_instance.memory_gb * 1024 * 1024 * 1024 } }
              annotations = {
                horizontal = [
                  {
                    color = "#ff0000"
                    label = "Alert"
                    value = local.rds_memory_alert_threshold[rds_instance.id]
                    fill  = "below"
                  }
                ]
              }
            }
          },
          // Disk Utilization
          {
            type   = "metric"
            x      = 8
            y      = local.rds_t_header_y + 1 + i * 14
            width  = 4
            height = 6
            properties = {
              metrics = [["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", rds_instance.id, { "color" : "#17caf6" }]]
              view    = "timeSeries"
              stat    = "Minimum"
              region  = data.aws_region.current.name
              period  = 60
              title   = "[RDS] Free Storage"
              yAxis   = { left = { min = 0, max = rds_instance.allocated_storage_gb * 1024 * 1024 * 1024 } }
              annotations = {
                horizontal = [
                  {
                    color = "#ff0000"
                    label = "Alert"
                    value = local.rds_storage_alert_threshold[rds_instance.id]
                    fill  = "below"
                  }
                ]
              }
            }
          },
          // Credit Usage
          {
            type   = "metric"
            x      = 12
            y      = local.rds_t_header_y + 1 + i * 14
            width  = 4
            height = 6
            properties = {
              title = "[RDS] Credit Usage"
              metrics = [
                ["AWS/RDS", "CPUCreditUsage", "DBInstanceIdentifier", rds_instance.id, { "color" : "#17caf6" }],
                ["AWS/RDS", "CPUCreditBalance", "DBInstanceIdentifier", rds_instance.id, { "color" : "#f66917" }]
              ]
              view   = "timeSeries"
              stat   = "Average"
              region = data.aws_region.current.name
              period = 60
              annotations = {
                horizontal = [
                  {
                    color = "#ff0000"
                    label = "Alert"
                    value = floor(lookup(local.rds_instances_credit, rds_instance.type, 0) * 0.4)
                    fill  = "above"
                  }
                ]
              }
            }
          },
          // Write/Read IOPS
          {
            type   = "metric"
            x      = 16
            y      = local.rds_t_header_y + 1 + i * 14
            width  = 4
            height = 6
            properties = {
              metrics = [
                ["AWS/RDS", "WriteIOPS", "DBInstanceIdentifier", rds_instance.id, { "color" : "#17caf6" }],
                ["AWS/RDS", "ReadIOPS", "DBInstanceIdentifier", rds_instance.id, { "color" : "#f66917" }]
              ]
              view   = "timeSeries"
              stat   = "Average"
              region = data.aws_region.current.name
              period = 60
              title  = "[RDS] Write/Read IOPS"
            }
          },
          // DB Connections
          {
            type   = "metric"
            x      = 20
            y      = local.rds_t_header_y + 1 + i * 14
            width  = 4
            height = 6
            properties = {
              metrics = [["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", rds_instance.id, { "color" : "#17caf6" }]]
              view    = "timeSeries"
              stat    = "Average"
              region  = data.aws_region.current.name
              period  = 60
              title   = "[RDS] DB Connections"
              annotations = {
                horizontal = [
                  {
                    label = "Alert"
                    value = local.t_instance_max_connections[rds_instance.id]
                    color = "#FF0000"
                    fill  = "above"
                  }
                ]
              }
            }
          }
        ]
      )
    ]),
    // Segundo grupo: local.RDS.rds_list
    flatten([
      for i, rds_instance in tolist(local.RDS.rds_without_t_list) : concat(
        [
          // Cabeçalho da instância
          {
            type   = "text"
            x      = 0
            y      = local.rds_header_y + 3 + i * 14
            width  = 24
            height = 2
            properties = {
              markdown   = "## ${rds_instance}\n[button:primary:${rds_instance}](https://${data.aws_region.current.name}.console.aws.amazon.com/rds/home?region=${data.aws_region.current.name}#database:id=${rds_instance})"
              background = "transparent"
            }
          }
        ],
        [
          // CPU Utilization
          {
            type   = "metric"
            x      = 0
            y      = local.rds_header_y + 3 + i * 14
            width  = 4
            height = 6
            properties = {
              metrics = [["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", rds_instance, { "color" : "#17caf6" }]]
              view    = "timeSeries"
              stat    = "Average"
              region  = data.aws_region.current.name
              period  = 60
              title   = "[RDS] CPU Utilization"
              yAxis   = { left = { min = 0, max = 100 } }
              annotations = {
                horizontal = [
                  {
                    color = "#ff0000"
                    label = "Alert"
                    value = 80
                    fill  = "above"
                  }
                ]
              }
            }
          },
          // Memory Utilization
          {
            type   = "metric"
            x      = 4
            y      = local.rds_header_y + 3 + i * 14
            width  = 4
            height = 6
            properties = {
              metrics = [["AWS/RDS", "FreeableMemory", "DBInstanceIdentifier", rds_instance, { "color" : "#17caf6" }]]
              view    = "timeSeries"
              stat    = "Average"
              region  = data.aws_region.current.name
              period  = 60
              title   = "[RDS] Free Memory"
              yAxis   = { left = { min = 0, max = [for inst in local.all_rds_instances : inst.memory_gb * 1024 * 1024 * 1024 if inst.id == rds_instance][0] } }
              annotations = {
                horizontal = [
                  {
                    color = "#ff0000"
                    label = "Alert"
                    value = local.rds_memory_alert_threshold[rds_instance]
                    fill  = "below"
                  }
                ]
              }
            }
          },
          // Disk Utilization
          {
            type   = "metric"
            x      = 8
            y      = local.rds_header_y + 3 + i * 14
            width  = 4
            height = 6
            properties = {
              metrics = [["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", rds_instance, { "color" : "#17caf6" }]]
              view    = "timeSeries"
              stat    = "Minimum"
              region  = data.aws_region.current.name
              period  = 60
              title   = "[RDS] Free Storage"
              yAxis   = { left = { min = 0, max = [for inst in local.all_rds_instances : inst.allocated_storage_gb * 1024 * 1024 * 1024 if inst.id == rds_instance][0] } }
              annotations = {
                horizontal = [
                  {
                    color = "#ff0000"
                    label = "Alert"
                    value = local.rds_storage_alert_threshold[rds_instance]
                    fill  = "below"
                  }
                ]
              }
            }
          },
          // DB Connections
          {
            type   = "metric"
            x      = 12
            y      = local.rds_header_y + 3 + i * 14
            width  = 4
            height = 6
            properties = {
              metrics = [["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", rds_instance, { "color" : "#17caf6" }]]
              view    = "timeSeries"
              stat    = "Average"
              region  = data.aws_region.current.name
              period  = 60
              title   = "[RDS] DB Connections"
              annotations = {
                horizontal = [
                  {
                    label = "Alert"
                    value = local.t_instance_max_connections[rds_instance]
                    color = "#FF0000"
                    fill  = "above"
                  }
                ]
              }
            }
          },
          // WriteIOPS
          {
            type   = "metric"
            x      = 16
            y      = local.rds_header_y + 3 + i * 14
            width  = 4
            height = 6
            properties = {
              metrics = [["AWS/RDS", "WriteIOPS", "DBInstanceIdentifier", rds_instance, { "color" : "#17caf6" }]]
              view    = "timeSeries"
              stat    = "Average"
              region  = data.aws_region.current.name
              period  = 60
              title   = "[RDS] WriteIOPS"
            }
          },
          // ReadIOPS
          {
            type   = "metric"
            x      = 20
            y      = local.rds_header_y + 3 + i * 14
            width  = 4
            height = 6
            properties = {
              metrics = [["AWS/RDS", "ReadIOPS", "DBInstanceIdentifier", rds_instance, { "color" : "#17caf6" }]]
              view    = "timeSeries"
              stat    = "Average"
              region  = data.aws_region.current.name
              period  = 60
              title   = "[RDS] ReadIOPS"
            }
          }
        ]
      )
    ])
  )

  # Widgets de Redis
  redis_widgets = flatten([
    for i, redis_id in tolist(local.redis_instances) : [
      {
        type   = "text"
        x      = 0
        y      = local.redis_header_y + 1 + i * 8
        width  = 24
        height = 2
        properties = {
          markdown   = "## ${redis_id}\n[button:primary:${redis_id}](https://${data.aws_region.current.name}.console.aws.amazon.com/elasticache/home?region=${data.aws_region.current.name}#cache-nodes:id=${redis_id})"
          background = "transparent"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = local.redis_header_y + 3 + i * 8
        width  = 6
        height = 6
        properties = {
          metrics = [["AWS/ElastiCache", "EngineCPUUtilization", "CacheClusterId", redis_id, { "color" : "#17caf6" }]]
          view    = "timeSeries"
          stat    = "Maximum"
          region  = data.aws_region.current.name
          period  = 60
          title   = "[REDIS] CPU Utilization"
          yAxis   = { left = { min = 0, max = 100 } }
          annotations = {
            horizontal = [
              {
                color = "#ff0000"
                label = "Alert"
                value = 80
                fill  = "above"
              }
            ]
          }
        }
      },
      {
        type   = "metric"
        x      = 6
        y      = local.redis_header_y + 3 + i * 8
        width  = 6
        height = 6
        properties = {
          metrics = [["AWS/ElastiCache", "BytesUsedForCache", "CacheClusterId", redis_id, { "color" : "#17caf6" }]]
          view    = "timeSeries"
          stat    = "Maximum"
          region  = data.aws_region.current.name
          period  = 60
          title   = "[REDIS] Data Stored"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = local.redis_header_y + 3 + i * 8
        width  = 6
        height = 6
        properties = {
          metrics = [
            ["AWS/ElastiCache", "CacheHits", "CacheClusterId", redis_id, { "color" : "#17caf6" }],
            ["AWS/ElastiCache", "CacheMisses", "CacheClusterId", redis_id, { "color" : "#f66917" }]
          ]
          view   = "timeSeries"
          stat   = "Average"
          region = data.aws_region.current.name
          period = 60
          title  = "[REDIS] Cache Rate"
        }
      },
      {
        type   = "metric"
        x      = 18
        y      = local.redis_header_y + 3 + i * 8
        width  = 6
        height = 6
        properties = {
          metrics = [["AWS/ElastiCache", "CurrConnections", "CacheClusterId", redis_id, { "color" : "#17caf6" }]]
          view    = "timeSeries"
          stat    = "Maximum"
          region  = data.aws_region.current.name
          period  = 60
          title   = "[REDIS] Connections"
        }
      }
    ]
  ])

  # Widgets de EFS
  efs_widgets = flatten([
    for i, efs_id in tolist(local.efs_instances) : [
      # Cabeçalho da instância EFS
      {
        type   = "text"
        x      = 0
        y      = local.efs_header_y + 1 + i * 12
        width  = 24
        height = 2
        properties = {
          markdown   = "## ${efs_id}\n[button:primary:${efs_id}](https://${data.aws_region.current.name}.console.aws.amazon.com/efs/home?region=${data.aws_region.current.name}#/file-systems/${efs_id})"
          background = "transparent"
        }
      },
      # Throughput utilization (%)
      {
        type   = "metric"
        x      = 0
        y      = local.efs_header_y + 3 + i * 12
        width  = 5
        height = 6
        properties = {
          metrics = [
            [{ "expression" : "(m1/1048576)/PERIOD(m1)", "label" : "Expression1", "id" : "e1", "region" : data.aws_region.current.name, "visible" : false }],
            [{ "expression" : "m2/1048576", "label" : "Expression2", "id" : "e2", "region" : data.aws_region.current.name, "visible" : false }],
            [{ "expression" : "e2-e1", "label" : "Expression3", "id" : "e3", "region" : data.aws_region.current.name, "visible" : false }],
            [{ "expression" : "((e1)*100)/(e2)", "label" : "Throughput utilization (%)", "id" : "e4", "region" : data.aws_region.current.name, "color" : "#17caf6" }],
            ["AWS/EFS", "MeteredIOBytes", "FileSystemId", efs_id, { "id" : "m1", "region" : data.aws_region.current.name, "visible" : false }],
            [".", "PermittedThroughput", ".", ".", { "id" : "m2", "region" : data.aws_region.current.name, "visible" : false }]
          ],
          view    = "timeSeries",
          stacked = false,
          region  = data.aws_region.current.name,
          stat    = "Sum",
          period  = 60,
          title   = "[EFS] Throughput utilization",
          annotations = {
            horizontal = [
              {
                color = "#ff0000",
                label = "Alert",
                value = 80,
                fill  = "above"
              }
            ]
          },
          yAxis = {
            left = {
              max       = 100,
              label     = "Percent",
              showUnits = false
            },
            right = {
              label     = "",
              showUnits = false
            }
          }
        }
      },
      # PercentIOLimit
      {
        type   = "metric"
        x      = 5
        y      = local.efs_header_y + 3 + i * 12
        width  = 5
        height = 6
        properties = {
          metrics = [
            ["AWS/EFS", "PercentIOLimit", "FileSystemId", efs_id, { "color" : "#17caf6" }]
          ],
          view    = "timeSeries",
          stacked = false,
          region  = data.aws_region.current.name,
          period  = 60,
          title   = "[EFS] PercentIOLimit",
          annotations = {
            horizontal = [
              {
                color = "#ff0000",
                label = "Alert",
                value = 80,
                fill  = "above"
              }
            ]
          },
          yAxis = {
            left = {
              min = 0,
              max = 100
            }
          },
          stat = "Maximum"
        }
      },
      # StorageBytes
      {
        type   = "metric"
        x      = 10
        y      = local.efs_header_y + 3 + i * 12
        width  = 5
        height = 6
        properties = {
          metrics = [
            ["AWS/EFS", "StorageBytes", "StorageClass", "Standard", "FileSystemId", efs_id, { "color" : "#17caf6" }]
          ],
          view    = "timeSeries",
          stacked = false,
          region  = data.aws_region.current.name,
          period  = 60,
          title   = "[EFS] StorageBytes",
          stat    = "Maximum"
        }
      },
      # Data Read/Write IO Bytes
      {
        type   = "metric"
        x      = 15
        y      = local.efs_header_y + 3 + i * 12
        width  = 5
        height = 6
        properties = {
          metrics = [
            ["AWS/EFS", "DataWriteIOBytes", "FileSystemId", efs_id, { "color" : "#17caf6" }],
            [".", "DataReadIOBytes", ".", ".", { "color" : "#f66917" }]
          ],
          view    = "timeSeries",
          stacked = false,
          region  = data.aws_region.current.name,
          period  = 300,
          yAxis = {
            left = {
              max       = 100,
              label     = "Percent",
              showUnits = false
            },
            right = {
              label     = "",
              showUnits = false
            }
          }
          title = "[EFS] Data Read/Write",
          stat  = "Average"
        }
      },
      # Client Connections
      {
        type   = "metric"
        x      = 20
        y      = local.efs_header_y + 3 + i * 12
        width  = 4
        height = 6
        properties = {
          metrics = [
            ["AWS/EFS", "ClientConnections", "FileSystemId", efs_id, { "color" : "#17caf6" }]
          ],
          annotations = {
            horizontal = [
              {
                color = "#ff0000",
                label = "Alert",
                value = 0,
                fill  = "below"
              }
            ]
          },
          view    = "timeSeries",
          stacked = false,
          region  = data.aws_region.current.name,
          period  = 300,
          title   = "[EFS] Client Connections",
          stat    = "Average"
        }
      }
    ]
  ])

  # Widgets de Auto Scaling Group
  asg_widgets = flatten([
    for i, asg_name in tolist(local.asg_instances) : [
      {
        type   = "text"
        x      = 0
        y      = local.asg_header_y + 1 + i * 8
        width  = 24
        height = 2
        properties = {
          markdown   = "## ${asg_name}\n[button:primary:${asg_name}](https://${data.aws_region.current.name}.console.aws.amazon.com/ec2/home?region=${data.aws_region.current.name}#AutoScalingGroupDetails:id=${asg_name})"
          background = "transparent"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = local.asg_header_y + 3 + i * 8
        width  = 5
        height = 7
        properties = {
          metrics = [
            ["AWS/AutoScaling", "GroupInServiceInstances", "AutoScalingGroupName", asg_name, { "region" : data.aws_region.current.name, "color" : "#17caf6" }]
          ]
          view                     = "timeSeries"
          stacked                  = false
          region                   = data.aws_region.current.name
          setPeriodToTimeRange     = false
          stat                     = "Maximum"
          period                   = 60
          singleValueFullPrecision = false
          sparkline                = true
          title                    = "[ASG] Active Instances"
          annotations = {
            horizontal = [
              {
                label = "Alert"
                value = 0
                fill  = "below"
              }
            ]
          }
          yAxis = {
            left = {
              min = 0
            }
          }
        }
      },
      {
        type   = "metric"
        x      = 5
        y      = local.asg_header_y + 3 + i * 8
        width  = 5
        height = 7
        properties = {
          metrics = [
            ["AWS/AutoScaling", "GroupMinSize", "AutoScalingGroupName", asg_name, { "region" : data.aws_region.current.name, "color" : "#17caf6" }],
            [".", "GroupMaxSize", ".", ".", { "region" : data.aws_region.current.name, "color" : "#f66917" }]
          ]
          view                     = "singleValue"
          stacked                  = true
          region                   = data.aws_region.current.name
          setPeriodToTimeRange     = false
          stat                     = "Maximum"
          period                   = 60
          singleValueFullPrecision = false
          sparkline                = true
          title                    = "[ASG] Min/Max Instances"
        }
      }
    ]
  ])
}