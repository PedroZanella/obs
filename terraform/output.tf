output "vm_public_ip" {
  value = aws_instance.obs_predo.public_ip
}

output "grafana_url" {
  value = "http://${aws_instance.obs_predo.public_ip}:3300"
}

output "prometheus_url" {
  value = "http://${aws_instance.obs_predo.public_ip}:9090"
}

output "node_exporter_url" {
  value = "http://${aws_instance.obs_predo.public_ip}:9100"
}

output "ping_exporter_url" {
  value = "http://${aws_instance.obs_predo.public_ip}:9427"
}