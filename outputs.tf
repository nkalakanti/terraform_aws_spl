#Outputs
output "private_ec2_id" {
  value = aws_instance.private-ec2.id
}

output "private_ec2_ip" {
  value = aws_instance.private-ec2.private_ip
}

output "public_ec2_id" {
  value = aws_instance.public-ec2.id
}

output "public_ec2_ip" {
  value = aws_eip.public-ip.public_ip
}

output "NAT_public_ip" {
  value = aws_eip.nat-gateway-ip.public_ip
}