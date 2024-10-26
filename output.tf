output "instance_public_ip" {
    value = aws_instance.website1-ec2.public_ip
}

output "private_key_pem" {
  value = tls_private_key.website1-ec2-key.private_key_pem
  sensitive = true
}

output "vpc_id" {
  value = aws_vpc.website1-vpc.id
}

output "vpc_endpoint_id" {
  value = aws_vpc_endpoint.website1-end.id
}