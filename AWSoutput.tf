output "public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.backend_server.public_ip
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.backend_server.id
}
