output "server_public_ip" {
  value = aws_instance.app_server.public_ip
}

output "application_url" {
  value = "https://${var.domain_name}"
}