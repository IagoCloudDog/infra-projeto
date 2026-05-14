output "RDS-local" {
  value = local.RDS
}

output "existing_instance_ids" {
  value = data.aws_instances.existing.ids
}

output "load_balancers" {
  value = data.external.load_balancers.result
}
