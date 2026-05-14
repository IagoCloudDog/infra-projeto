output "vpn-instance_arn" {
  description = "ARN da Instância OpenVPN provisionada"
  value       = aws_instance.openvpn.arn
}

output "instance_ip" {
  description = "IP da Instância OpenVPN provisionada"
  value       = aws_eip.openvpn_eip.address
}

output "instance_id" {
  value = aws_instance.openvpn.id
}