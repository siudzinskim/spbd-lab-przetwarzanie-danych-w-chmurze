output "aws_instance_id" {
  value = aws_instance.lab_instance.id
}

output "aws-volume" {
  value = aws_ebs_volume.example.id
}

output "network_cidr" {
  value = data.aws_vpc.main.cidr_block
}

output "subnetwork_cidr" {
  value = aws_subnet.public.cidr_block
}

output "aws_instance-public_ip" {
  value = aws_instance.lab_instance.public_ip
}